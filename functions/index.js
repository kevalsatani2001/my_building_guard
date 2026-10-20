const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");

/**
 * firebase-admin ભારે છે — ટોપ લેવલ પર require કરવાથી `firebase deploy` દરમ્યાન
 * "Timeout after 10000" / backend specification લોડ ન થાય. હેન્ડલર ચાલે ત્યારે જ લોડ કરો.
 * @returns {import("firebase-admin")}
 */
function getAdmin() {
    const admin = require("firebase-admin");
    if (!admin.apps.length) {
        admin.initializeApp();
        return admin;
    }
    try {
        admin.app();
    } catch (e) {
        admin.initializeApp();
    }
    return admin;
}

/**
 * Cloud Firestore instance મેળવો.
 * Flutter એપ 'building-guard' ડેટાબેઝ વાપરે છે (AppFirestore.databaseId = 'building-guard').
 * લેગસી સપોર્ટ માટે '(default)' પણ સપોર્ટેડ છે.
 */
function getFirestoreDb(databaseId = "building-guard") {
    const admin = getAdmin();
    try {
        const { getFirestore } = require("firebase-admin/firestore");
        if (databaseId) {
            return getFirestore(admin.app(), databaseId);
        }
        return getFirestore(admin.app());
    } catch (e) {
        return admin.firestore();
    }
}

/**
 * યુઝર ડોક્યુમેન્ટ શોધો — પહેલા 'building-guard' માં, ન મળે તો '(default)' માં.
 */
async function getUserDoc(uid) {
    if (!uid) return null;
    const targetUid = String(uid).trim();
    // 1. Primary app database: building-guard
    try {
        const bgDb = getFirestoreDb("building-guard");
        const doc = await bgDb.collection("users").doc(targetUid).get();
        if (doc.exists) return { doc, db: bgDb };
    } catch (e) {
        console.warn("getUserDoc 'building-guard' error:", e);
    }
    // 2. Fallback to default database
    try {
        const defDb = getFirestoreDb("(default)");
        const doc = await defDb.collection("users").doc(targetUid).get();
        if (doc.exists) return { doc, db: defDb };
    } catch (e) {
        console.warn("getUserDoc '(default)' error:", e);
    }
    return null;
}

/** FCM ટોપિક: ડિફૉલ્ટ સોસાયટી = લેગસી નામ, બાકી `soc_{slug}_{kind}`. */
function fcmSlug(societyId) {
    const s = String(societyId || "default").replace(/[^a-zA-Z0-9_-]/g, "_");
    return s.substring(0, 80) || "x";
}

function topicForSociety(societyId, kind) {
    const sid = societyId && String(societyId).trim() ? String(societyId).trim() : "default";
    if (sid === "default") {
        if (kind === "members") return "society_members";
        if (kind === "admins") return "society_admins";
        if (kind === "watchmen") return "society_watchmen";
    }
    const slug = fcmSlug(sid);
    if (kind === "members") return `soc_${slug}_members`;
    if (kind === "admins") return `soc_${slug}_admins`;
    if (kind === "watchmen") return `soc_${slug}_watchmen`;
    return "society_members";
}

function formatMessagingError(err) {
    if (!err) return "unknown";
    if (typeof err.code === "string" && err.message) {
        return `${err.code}: ${err.message}`.replace(/\s+/g, " ").trim().substring(0, 800);
    }
    if (typeof err.errorInfo === "object" && err.errorInfo && err.errorInfo.message) {
        return `${err.errorInfo.code || err.code || "messaging"}: ${err.errorInfo.message}`
            .replace(/\s+/g, " ")
            .trim()
            .substring(0, 800);
    }
    if (err.message) return String(err.message).replace(/\s+/g, " ").trim().substring(0, 800);
    try {
        return JSON.stringify(err).substring(0, 400);
    } catch (e) {
        return String(err);
    }
}

/** Android-first; `apns` હટાવ્યું — પ્રોજેક્ટમાં APNs સેટ ન હોય ત્યારે FCM INTERNAL ભૂલ આવતી હતી. */
function buildFcmParts(title, body, typeStr, senderUid = "") {
    const dataPayload = {
        type: String(typeStr),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        title: String(title),
        body: String(body),
        senderUid: String(senderUid || ""),
    };
    const android = {
        priority: "high",
        notification: {
            channelId: "high_importance_channel",
            sound: "default",
        },
    };
    return {
        dataPayload,
        android,
        notification: { title, body },
    };
}

/**
 * @param {"member"|"admin"|"watchman"} allowedRole
 * @param {string} excludeUid - જો મોકલનારનો UID હોય તો એમના પોતાના ડિવાઇસને બાકાત રાખવા
 */
async function collectTokensByRole(admin, societyId, allowedRole, excludeUid = "") {
    const tokens = new Set();
    const sidNorm = (u) => (u.societyId != null && String(u.societyId).trim() ?
        String(u.societyId).trim() : "default");

    const databasesToScan = ["building-guard", "(default)"];
    for (const dbName of databasesToScan) {
        try {
            const db = getFirestoreDb(dbName);
            let snap;
            if (societyId === "default") {
                snap = await db.collection("users").get();
            } else {
                snap = await db.collection("users").where("societyId", "==", societyId).get();
            }
            snap.forEach((doc) => {
                if (excludeUid && doc.id === excludeUid) return;
                const u = doc.data();
                if (!u || u.role !== allowedRole) return;
                if (sidNorm(u) !== societyId) return;
                const t = u.fcmToken;
                if (t && typeof t === "string" && t.trim()) tokens.add(t.trim());
            });
        } catch (e) {
            console.warn(`collectTokensByRole error on ${dbName}:`, e);
        }
    }
    return Array.from(tokens);
}

async function sendMulticastTokens(admin, tokens, parts) {
    if (!tokens.length) return { successCount: 0, failureCount: 0 };
    const chunkSize = 500;
    let successCount = 0;
    let failureCount = 0;
    for (let i = 0; i < tokens.length; i += chunkSize) {
        const chunk = tokens.slice(i, i + chunkSize);
        const messages = chunk.map((token) => ({
            token,
            notification: parts.notification,
            data: parts.dataPayload,
            android: parts.android,
        }));
        const res = await admin.messaging().sendEach(messages);
        successCount += res.successCount;
        failureCount += res.failureCount;
    }
    return { successCount, failureCount };
}

/**
 * પહેલા FCM ટોપિક; નિષ્ફળ થાય તો સમાન સોસાયટીના યુઝર્સના ટોકન પર multicast.
 * @param {"members"|"admins"|"watchmen"} kind
 * @param {string} senderUid
 */
async function sendTopicOrFanoutByRole(admin, societyId, kind, title, body, typeStr, senderUid = "") {
    const topic = topicForSociety(societyId, kind);
    const parts = buildFcmParts(title, body, typeStr, senderUid);
    const message = {
        topic,
        notification: parts.notification,
        data: parts.dataPayload,
        android: parts.android,
    };
    try {
        await admin.messaging().send(message);
        return { mode: "topic", topic };
    } catch (topicErr) {
        console.error("sendTopicOrFanoutByRole topic failed", topic, formatMessagingError(topicErr));
        const roleMap = { members: "member", admins: "admin", watchmen: "watchman" };
        const allowedRole = roleMap[kind];
        const tokens = await collectTokensByRole(admin, societyId, allowedRole, senderUid);
        if (!tokens.length) {
            throw new Error(`No device tokens for ${kind}. Topic error: ${formatMessagingError(topicErr)}`);
        }
        const mc = await sendMulticastTokens(admin, tokens, parts);
        if (mc.successCount < 1) {
            throw new Error(
                `Multicast failed (${mc.failureCount} fails). Topic error: ${formatMessagingError(topicErr)}`,
            );
        }
        return {
            mode: "fanout",
            topic,
            devices: tokens.length,
            successCount: mc.successCount,
            failureCount: mc.failureCount,
        };
    }
}

/**
 * વોચમેન અથવા એડમિન તરફથી સભ્યને સીધું FCM.
 * Flutter: httpsCallable('sendMemberPush')
 */
exports.sendMemberPush = onCall(async (request) => {
    try {
        const admin = getAdmin();
        if (!request.auth) {
            throw new HttpsError("unauthenticated", "લોગિન જરૂરી છે");
        }

        const payload = request.data && typeof request.data === "object" ? request.data : {};

        const callerRes = await getUserDoc(request.auth.uid);
        const callerDoc = callerRes ? callerRes.doc : null;
        const role = callerDoc && callerDoc.exists ? callerDoc.data().role : "";
        if (role !== "watchman" && role !== "admin") {
            throw new HttpsError("permission-denied", "માત્ર વોચમેન અથવા એડમિન");
        }

        const memberUid = payload.memberUid != null ? String(payload.memberUid).trim() : "";
        const title = String(payload.title != null ? payload.title : "").trim();
        const body = String(payload.body != null ? payload.body : "").trim();
        const type = payload.type != null ? String(payload.type) : "visitor_alert";
        const passedToken = payload.fcmToken != null ? String(payload.fcmToken).trim() : "";

        if (!memberUid || !title || !body) {
            throw new HttpsError("invalid-argument", "memberUid, title, body જરૂરી છે");
        }

        const callerSid = callerDoc && callerDoc.exists ? callerDoc.data().societyId : null;
        const callerSociety = callerSid && String(callerSid).trim() ? String(callerSid).trim() : "default";

        const userRes = await getUserDoc(memberUid);
        const userDoc = userRes ? userRes.doc : null;
        if ((!userDoc || !userDoc.exists) && !passedToken) {
            throw new HttpsError("not-found", "મેમ્બર મળ્યો નથી");
        }

        const memData = userDoc && userDoc.exists ? userDoc.data() : null;
        if (memData) {
            const memSid = memData.societyId;
            const memSociety = memSid && String(memSid).trim() ? String(memSid).trim() : "default";
            if (memSociety !== callerSociety) {
                throw new HttpsError("permission-denied", "અલગ સોસાયટીનો મેમ્બર");
            }
        }

        let fcmToken = (memData && memData.fcmToken) ? String(memData.fcmToken).trim() : passedToken;
        if (!fcmToken) {
            console.warn("sendMemberPush: no fcmToken", memberUid);
            return { ok: false, reason: "no_token" };
        }

        const dataPayload = {
            type: String(type),
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            title: String(title),
            body: String(body),
            senderUid: String(request.auth.uid || ""),
        };

        try {
            await admin.messaging().send({
                token: fcmToken,
                notification: { title, body },
                data: dataPayload,
                android: {
                    priority: "high",
                    notification: {
                        channelId: "high_importance_channel",
                        sound: "default",
                    },
                },
            });
            console.log("sendMemberPush ok", memberUid);
            return { ok: true };
        } catch (e) {
            console.error("sendMemberPush send error", e);
            return { ok: false, reason: String(e.message || e) };
        }
    } catch (err) {
        console.error("sendMemberPush fatal", err);
        if (err instanceof HttpsError) {
            throw err;
        }
        return { ok: false, reason: String(err && err.message ? err.message : err) };
    }
});

/**
 * એડમિન એપથી બધા મેમ્બર્સને સીધું FCM ટોપિક / fan-out.
 */
exports.sendBroadcastPush = onCall(async (request) => {
    const admin = getAdmin();
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "લોગિન જરૂરી છે");
    }

    const callerRes = await getUserDoc(request.auth.uid);
    const callerDoc = callerRes ? callerRes.doc : null;
    if (!callerDoc || !callerDoc.exists || callerDoc.data().role !== "admin") {
        throw new HttpsError("permission-denied", "માત્ર એડમિન");
    }

    const payload = request.data && typeof request.data === "object" ? request.data : {};
    const title = String(payload.title != null ? payload.title : "").trim();
    const body = String(payload.body != null ? payload.body : "").trim();
    const type = payload.type != null ? String(payload.type) : "general";

    if (!title || !body) {
        throw new HttpsError("invalid-argument", "title અને body જરૂરી છે");
    }

    const callerSid = callerDoc.data().societyId;
    const societyId = callerSid && String(callerSid).trim() ? String(callerSid).trim() : "default";
    const senderUid = request.auth.uid;

    try {
        const r = await sendTopicOrFanoutByRole(admin, societyId, "members", title, body, type, senderUid);
        console.log("sendBroadcastPush ok", societyId, r);
        const out = { ok: true, mode: r.mode, topic: r.topic };
        if (typeof r.devices === "number") out.devices = r.devices;
        if (typeof r.successCount === "number") out.successCount = r.successCount;
        if (typeof r.failureCount === "number") out.failureCount = r.failureCount;
        return out;
    } catch (e) {
        console.error("sendBroadcastPush error", e);
        const msg = formatMessagingError(e) || "sendBroadcastPush failed";
        throw new HttpsError("failed-precondition", msg);
    }
});

/**
 * એડમિન / વોચમેન / મેમ્બર — `society_admins` અથવા `society_watchmen` ટોપિક.
 * SOS / ઇમરજન્સી એલર્ટ.
 */
exports.sendTopicAlertPush = onCall(async (request) => {
    const admin = getAdmin();
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "લોગિન જરૂરી છે");
    }

    const callerRes = await getUserDoc(request.auth.uid);
    const callerDoc = callerRes ? callerRes.doc : null;
    if (!callerDoc || !callerDoc.exists) {
        throw new HttpsError("not-found", "યુઝર મળ્યો નથી");
    }

    const role = callerDoc.data().role;
    if (role !== "member" && role !== "watchman" && role !== "admin") {
        throw new HttpsError("permission-denied", "અનધિકૃત");
    }

    const payload = request.data && typeof request.data === "object" ? request.data : {};
    const topicKind = String(payload.topicKind != null ? payload.topicKind : "").toLowerCase().trim();
    if (topicKind !== "admins" && topicKind !== "watchmen") {
        throw new HttpsError("invalid-argument", "topicKind: admins અથવા watchmen");
    }

    const title = String(payload.title != null ? payload.title : "").trim();
    const body = String(payload.body != null ? payload.body : "").trim();
    const type = payload.type != null ? String(payload.type) : "alert";

    if (!title || !body) {
        throw new HttpsError("invalid-argument", "title અને body જરૂરી છે");
    }

    const callerSid = callerDoc.data().societyId;
    const societyId = callerSid && String(callerSid).trim() ? String(callerSid).trim() : "default";
    const kind = topicKind === "admins" ? "admins" : "watchmen";
    const senderUid = request.auth.uid;

    try {
        const r = await sendTopicOrFanoutByRole(admin, societyId, kind, title, body, type, senderUid);
        console.log("sendTopicAlertPush ok", societyId, kind, r);
        const out = { ok: true, mode: r.mode, topic: r.topic };
        if (typeof r.devices === "number") out.devices = r.devices;
        if (typeof r.successCount === "number") out.successCount = r.successCount;
        if (typeof r.failureCount === "number") out.failureCount = r.failureCount;
        return out;
    } catch (e) {
        console.error("sendTopicAlertPush error", e);
        const msg = formatMessagingError(e) || "sendTopicAlertPush failed";
        throw new HttpsError("failed-precondition", msg);
    }
});

// ૧. મેન્યુઅલ નોટિફિકેશન મોકલવા માટે (v2) — 'building-guard' ડેટાબેઝ પર લિસન કરે છે.
exports.sendNotification = onDocumentCreated({
    document: "notifications/{notifId}",
    database: "building-guard",
}, async (event) => {
    const admin = getAdmin();
    const notifId = event.params.notifId;
    const db = getFirestoreDb("building-guard");
    const notifRef = db.collection("notifications").doc(notifId);

    let snap = event.data;
    if (!snap || typeof snap.data !== "function") {
        snap = await notifRef.get();
    }
    if (!snap || !snap.exists) {
        return null;
    }
    const data = snap.data();
    if (!data) return null;

    // 🛑 DEDUPLICATION GUARD:
    // જો નોટિફિકેશન ક્લાયન્ટ દ્વારા સીધા Callable Function (sendMemberPush / sendBroadcastPush) થી મોકલાઈ ગયું હોય,
    // અથવા skipTriggerPush: true હોય, તો ટ્રિગરમાંથી ફરી FCM પુશ ન મોકલો જેથી ડુપ્લિકેટ (2 વખત) નોટિફિકેશન ન આવે.
    if (data.skipTriggerPush === true ||
        data.deliveryMode === "direct_callable" ||
        (data.fcmDeliveryStatus && String(data.fcmDeliveryStatus).startsWith("sent_"))) {
        console.log(`sendNotification: skipping trigger FCM push for ${notifId} (skipTriggerPush: ${data.skipTriggerPush}, deliveryMode: ${data.deliveryMode}, status: ${data.fcmDeliveryStatus})`);
        return null;
    }

    const mark = async (status, extra = {}) => {
        try {
            await notifRef.set({
                fcmDeliveryStatus: status,
                fcmProcessedAt: admin.firestore.FieldValue.serverTimestamp(),
                ...extra,
            }, {merge: true});
        } catch (e) {
            console.error("sendNotification: mark failed", e);
        }
    };

    const title = data.title != null ? String(data.title).trim() : "";
    const body = data.body != null ? String(data.body).trim() : "";
    const rawTarget = data.targetUID;
    const targetUID = rawTarget != null && String(rawTarget).trim() ? String(rawTarget).trim() : "";
    const societyRaw = data.societyId;
    const societyId = societyRaw && String(societyRaw).trim() ? String(societyRaw).trim() : "default";

    if (!title || !body) {
        await mark("skipped_invalid", {fcmDetail: "missing_title_or_body"});
        return null;
    }
    if (!targetUID) {
        await mark("skipped_invalid", {fcmDetail: "missing_targetUID"});
        return null;
    }

    const typeStr = String(data.type || "general");
    const senderUid = String(data.senderUid || data.authorId || "");

    try {
        if (targetUID === "ALL") {
            const r = await sendTopicOrFanoutByRole(admin, societyId, "members", title, body, typeStr, senderUid);
            const st = r.mode === "topic" ? "sent_topic_members" : "sent_fanout_members";
            await mark(st, {fcmDetail: JSON.stringify(r)});
        } else if (targetUID === "ADMINS") {
            const r = await sendTopicOrFanoutByRole(admin, societyId, "admins", title, body, typeStr, senderUid);
            const st = r.mode === "topic" ? "sent_topic_admins" : "sent_fanout_admins";
            await mark(st, {fcmDetail: JSON.stringify(r)});
        } else if (targetUID === "WATCHMEN") {
            const r = await sendTopicOrFanoutByRole(admin, societyId, "watchmen", title, body, typeStr, senderUid);
            const st = r.mode === "topic" ? "sent_topic_watchmen" : "sent_fanout_watchmen";
            await mark(st, {fcmDetail: JSON.stringify(r)});
        } else {
            if (senderUid && targetUID === senderUid) {
                await mark("skipped_self_sender", {fcmDetail: "targetUID matches senderUid"});
                return null;
            }
            const userRes = await getUserDoc(targetUID);
            if (!userRes || !userRes.doc.exists) {
                await mark("skipped_user_not_found", {fcmDetail: String(targetUID)});
                return null;
            }

            const ud = userRes.doc.data();
            const rawTok = ud && ud.fcmToken;
            const fcmToken = rawTok && typeof rawTok === "string" ? rawTok.trim() : "";
            if (!fcmToken) {
                await mark("skipped_no_token", {fcmDetail: String(targetUID)});
                return null;
            }
            const parts = buildFcmParts(title, body, typeStr);
            await admin.messaging().send({
                token: fcmToken,
                notification: parts.notification,
                data: parts.dataPayload,
                android: parts.android,
            });
            await mark("sent_token", {fcmDetail: String(targetUID)});
        }
    } catch (error) {
        console.error("Error sending notification:", error);
        await mark("error", {fcmError: formatMessagingError(error)});
    }
    return null;
});

// ૨. વિઝિટર સ્ટેટસ બદલાય ત્યારે
exports.onStatusChange = onDocumentUpdated({
    document: "visitors/{visitorId}",
    database: "building-guard",
}, async (event) => {
    const admin = getAdmin();
    const newData = event.data.after.data();
    const oldData = event.data.before.data();

    if (oldData.status === newData.status) {
        return null;
    }

    const db = getFirestoreDb("building-guard");
    const visitorName = newData.name || "મહેમાન";
    const visitorDocId = event.params.visitorId;

    try {
        if (newData.status === "approved" || newData.status === "rejected") {
            const widRaw = newData.watchmanId;
            const watchmanId = widRaw != null ? String(widRaw).trim() : "";
            if (!watchmanId) {
                console.error("onStatusChange: missing watchmanId on visitor doc", visitorDocId);
                return null;
            }
            const msgStatus = newData.status === "approved" ? "મંજૂરી મળી ગઈ છે ✅" : "ના પાડી છે ❌";
            const vsid = newData.societyId;
            const societyId = vsid && String(vsid).trim() ? String(vsid).trim() : "default";
            await db.collection("notifications").add({
                title: "મેમ્બરનો જવાબ આવ્યો!",
                body: `${visitorName} માટે: ${msgStatus}`,
                targetUID: watchmanId,
                type: "visitor_response",
                relatedVisitorId: visitorDocId,
                societyId,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
            console.log("visitor_response notification queued for watchman", watchmanId);
        }
    } catch (error) {
        console.error("onStatusChange error:", error);
    }
    return null;
});
