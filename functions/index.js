const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// ૧. મેન્યુઅલ નોટિફિકેશન મોકલવા માટે (v2)
exports.sendNotification = onDocumentCreated("notifications/{notifId}", async (event) => {
    const data = event.data.data();
    const title = data.title;
    const body = data.body;
    const targetUID = data.targetUID;

    try {
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
        if (newData.status === "checked_out") {
            const memberId = newData.memberId;
            if (!memberId || String(memberId).trim() === "") {
                console.error("onStatusChange checked_out: missing memberId", visitorDocId);
                return null;
            }
            await db.collection("notifications").add({
                title: "મહેમાન બહાર ગયા 🚪",
                body: `${visitorName} સોસાયટીની બહાર નીકળી ગયા છે.`,
                targetUID: String(memberId),
                type: "visitor_checked_out",
                relatedVisitorId: visitorDocId,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
            console.log("checkout notification queued for member", memberId);
            return null;
        }

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
