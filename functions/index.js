const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * વોચમેન એપમાંથી સીધું FCM — Firestore `notifications` ટ્રિગર પર નિર્ભર નથી.
 * Flutter: FirebaseFunctions.instance.httpsCallable('sendMemberPush')
 */
exports.sendMemberPush = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "લોગિન જરૂરી છે");
    }

    const callerDoc = await admin.firestore().collection("users").doc(request.auth.uid).get();
    const role = callerDoc.exists ? callerDoc.data().role : "";
    if (role !== "watchman" && role !== "admin") {
        throw new HttpsError("permission-denied", "માત્ર વોચમેન અથવા એડમિન");
    }

    const memberUid = request.data.memberUid;
    const title = request.data.title;
    const body = request.data.body;
    const type = request.data.type || "visitor_alert";

    if (!memberUid || !title || !body) {
        throw new HttpsError("invalid-argument", "memberUid, title, body જરૂરી છે");
    }

    const userDoc = await admin.firestore().collection("users").doc(String(memberUid)).get();
    if (!userDoc.exists) {
        throw new HttpsError("not-found", "મેમ્બર મળ્યો નથી");
    }

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
        console.warn("sendMemberPush: no fcmToken", memberUid);
        return { ok: false, reason: "no_token" };
    }

    const dataPayload = {
        type: String(type),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
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
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                    },
                },
            },
        });
        console.log("sendMemberPush ok", memberUid);
        return { ok: true };
    } catch (e) {
        console.error("sendMemberPush send error", e);
        return { ok: false, reason: String(e.message || e) };
    }
});

// ૧. મેન્યુઅલ નોટિફિકેશન મોકલવા માટે (v2)
exports.sendNotification = onDocumentCreated("notifications/{notifId}", async (event) => {
    const data = event.data.data();
    const title = data.title;
    const body = data.body;
    const targetUID = data.targetUID;

    try {
        if (!title || !body) {
            console.warn("sendNotification: missing title or body", event.params.notifId);
            return null;
        }
        const dataPayload = {
            type: String(data.type || "general"),
            click_action: "FLUTTER_NOTIFICATION_CLICK",
        };

        const fcmOptions = {
            notification: { title, body },
            data: dataPayload,
            android: {
                priority: "high",
                notification: {
                    channelId: "high_importance_channel",
                    sound: "default",
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                    },
                },
            },
        };

        if (targetUID === "ALL") {
            const message = { topic: "society_members", ...fcmOptions };
            await admin.messaging().send(message);
            console.log("Broadcast sent successfully");
        } else {
            const userDoc = await admin.firestore().collection("users").doc(String(targetUID)).get();
            if (!userDoc.exists) return null;

            const fcmToken = userDoc.data().fcmToken;
            if (fcmToken) {
                const message = { token: fcmToken, ...fcmOptions };
                await admin.messaging().send(message);
            } else {
                console.warn("sendNotification: no fcmToken for user", targetUID);
            }
        }
    } catch (error) {
        console.error("Error sending notification:", error);
    }
    return null;
});

// ૨. વિઝિટર સ્ટેટસ બદલાય ત્યારે — same path as gate alerts: queue `notifications` so sendNotification delivers FCM (all platforms).
exports.onStatusChange = onDocumentUpdated("visitors/{visitorId}", async (event) => {
    const newData = event.data.after.data();
    const oldData = event.data.before.data();

    if (oldData.status === newData.status) {
        return null;
    }

    const db = admin.firestore();
    const visitorName = newData.name || "મહેમાન";
    const visitorDocId = event.params.visitorId;

    try {
        // checked_out મેમ્બર પુશ: વોચમેન એપ `sendMemberPush` callable થી મોકલે (વધુ વિશ્વસનીય)

        if (newData.status === "approved" || newData.status === "rejected") {
            const widRaw = newData.watchmanId;
            const watchmanId = widRaw != null ? String(widRaw).trim() : "";
            if (!watchmanId) {
                console.error("onStatusChange approve/reject: missing watchmanId on visitor doc", visitorDocId, JSON.stringify(newData));
                return null;
            }
            const msgStatus = newData.status === "approved" ? "મંજૂરી મળી ગઈ છે ✅" : "ના પાડી છે ❌";
            await db.collection("notifications").add({
                title: "મેમ્બરનો જવાબ આવ્યો!",
                body: `${visitorName} માટે: ${msgStatus}`,
                targetUID: watchmanId,
                type: "visitor_response",
                relatedVisitorId: visitorDocId,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
            console.log("visitor_response notification queued for watchman", watchmanId);
        }
    } catch (error) {
        console.error("onStatusChange error:", error);
    }
    return null;
});
