const functions = require("firebase-functions");
const admin = require('firebase-admin');
admin.initializeApp();


exports.sendPushNotification = functions.https.onCall(async (data, context) => {
	try {
		const { type, title, body, deviceToken, senderId, call } = data;

		// Validate parameters
		if (!type || !title || !body || !deviceToken || !senderId) {
			throw new functions.https.HttpsError("invalid-argument", "Invalid parameters.");
		}

		// Build notification message
		const message = {
			notification: {
				title: title,
				body: body,
			},
			data: {
				n_type: type,
				n_sender_id: senderId,
				n_message: body,
				call_info: JSON.stringify(call || {}),
				click_action: "FLUTTER_NOTIFICATION_CLICK",
				status: "done",
			},
			android: {
				priority: "high",
				notification: {
					color: "#7F3BBF",
				},
			},
			apns: {
				payload: {
					aps: {
						contentAvailable: true,
						sound: "default",
					},
				},
			},
		};

		// Check admin push
		if (deviceToken == 'admin') {
			message.topic = 'NOTIFY_USERS';
		} else {
			message.token = deviceToken;
		}

		const response = await admin.messaging().send(message);
		const successMsg = `Send push notification success. Response: ${response}`;
		console.log(successMsg);
		return successMsg;
	} catch (error) {
		const errorMsg = `Failed to send push notification. ${error}`;
		console.error(errorMsg);
		throw new functions.https.HttpsError('internal', errorMsg);
	}
});

// Nettoyage automatique des Sparks expirés - exécuté toutes les heures
exports.cleanupExpiredSparks = functions.pubsub
	.schedule('every 1 hours')
	.onRun(async (context) => {
		const now = admin.firestore.Timestamp.now();

		const expiredSparks = await admin.firestore()
			.collection('Sparks')
			.where('expires_at', '<', now)
			.where('status', '==', 'pending')
			.get();

		const batch = admin.firestore().batch();

		expiredSparks.docs.forEach((doc) => {
			batch.update(doc.ref, { status: 'expired' });
		});

		await batch.commit();

		console.log(`Cleaned up ${expiredSparks.docs.length} expired sparks`);
		return null;
	});