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

/**
 * Cloud Function: Migrate preferences questions to new structure (19 questions, 7 sections)
 * Must be called ONCE ONLY via HTTP or Firebase Console
 * Workflow:
 * 1. Mark all existing questions as inactive
 * 2. Add 19 new questions with section organization
 * 3. Validate: 19 questions active, no duplicates
 */
exports.migratePreferencesQuestions = functions.https.onCall(async (data, context) => {
	// Require authentication (optional: can be made public with env check)
	// if (!context.auth?.uid) {
	//   throw new functions.https.HttpsError("unauthenticated", "User not authenticated");
	// }

	const db = admin.firestore();
	const newQuestions = [
		// SECTION 1: WHAT YOU WANT IN LOVE
		{
			id: "q_1_1",
			question: "What do you want a relationship to be in your life?",
			section: 1,
			sectionTitle: "WHAT YOU WANT IN LOVE",
			sectionOrder: 1,
			questionOrder: 1,
			type: "single",
			answers: {
				a: "A place that supports me while I grow",
				b: "A team where we build a life together",
				c: "A close and deep emotional bond",
				d: "Something natural that grows without pressure",
			},
			answerKeys: ["a", "b", "c", "d"],
			active: true,
			createdAt: admin.firestore.FieldValue.serverTimestamp(),
		},
		{
			id: "q_1_2",
			question: "How do you feel about having kids in the future?",
			section: 1,
			sectionTitle: "WHAT YOU WANT IN LOVE",
			sectionOrder: 2,
			questionOrder: 2,
			type: "single",
			answers: {
				a: "I want kids",
				b: "Yes, but later",
				c: "I'm not sure",
				d: "I don't want kids",
				e: "I'm open to someone who already has kids",
			},
			answerKeys: ["a", "b", "c", "d", "e"],
			active: true,
			createdAt: admin.firestore.FieldValue.serverTimestamp(),
		},
		{
			id: "q_1_3",
			question: "What do you hope to create with a partner?",
			section: 1,
			sectionTitle: "WHAT YOU WANT IN LOVE",
			sectionOrder: 3,
			questionOrder: 3,
			type: "single",
			answers: {
				a: "A family",
				b: "A stable life with shared goals",
				c: "Fun adventures and new experiences",
				d: "Personal growth and emotional support",
			},
			answerKeys: ["a", "b", "c", "d"],
			active: true,
			createdAt: admin.firestore.FieldValue.serverTimestamp(),
		},
		{
			id: "q_1_4",
			question: "What dating pace feels right for you?",
			section: 1,
			sectionTitle: "WHAT YOU WANT IN LOVE",
			sectionOrder: 4,
			questionOrder: 4,
			type: "single",
			answers: {
				a: "Slow and steady",
				b: "Natural and comfortable",
				c: "Fast connection",
				d: "It depends on our chemistry",
			},
			answerKeys: ["a", "b", "c", "d"],
			active: true,
			createdAt: admin.firestore.FieldValue.serverTimestamp(),
		},

		// SECTION 2: HOW YOU HANDLE FEELINGS
		{
			id: "q_2_5",
			question: "When you feel upset in a relationship, what do you usually do?",
			section: 2,
			sectionTitle: "HOW YOU HANDLE FEELINGS",
			sectionOrder: 1,
			questionOrder: 5,
			type: "single",
			answers: {
				a: "I need space to think",
				b: "I want comfort or reassurance",
				c: "I talk about how I feel",
				d: "I shut down or try to distract myself",
			},
			answerKeys: ["a", "b", "c", "d"],
			active: true,
			createdAt: admin.firestore.FieldValue.serverTimestamp(),
		},
		{
			id: "q_2_6",
			question: "How much alone time do you like in a relationship?",
			section: 2,
			sectionTitle: "HOW YOU HANDLE FEELINGS",
			sectionOrder: 2,
			questionOrder: 6,
			type: "single",
			answers: {
				a: "A lot — I like space",
				b: "A balance of space and closeness",
				c: "I like talking and connecting every day",
				d: "It depends on the partner",
			},
			answerKeys: ["a", "b", "c", "d"],
			active: true,
			createdAt: admin.firestore.FieldValue.serverTimestamp(),
		},

		// SECTION 3: HOW YOU COMMUNICATE
		{
			id: "q_3_7",
			question: "How do you act during disagreements?",
			section: 3,
			sectionTitle: "HOW YOU COMMUNICATE",
			sectionOrder: 1,
			questionOrder: 7,
			type: "single",
			answers: {
				a: "I stay calm and try to solve it",
				b: "I get emotional but want things to work out",
				c: "I shut down or avoid talking",
				d: "I feel strong emotions but want clarity",
			},
			answerKeys: ["a", "b", "c", "d"],
			active: true,
			createdAt: admin.firestore.FieldValue.serverTimestamp(),
		},
		{
			id: "q_3_8",
			question: "How do you prefer to fix problems?",
			section: 3,
			sectionTitle: "HOW YOU COMMUNICATE",
			sectionOrder: 2,
			questionOrder: 8,
			type: "single",
			answers: {
				a: "I talk about it right away.",
				b: "I need some space to calm down first.",
				c: "I need time to understand my feelings before I talk.",
				d: "I wait until it feels safe or really needed.",
			},
			answerKeys: ["a", "b", "c", "d"],
			active: true,
			createdAt: admin.firestore.FieldValue.serverTimestamp(),
		},
		{
			id: "q_3_9",
			question: "How do you make decisions with a partner?",
			section: 3,
			sectionTitle: "HOW YOU COMMUNICATE",
			sectionOrder: 3,
			questionOrder: 9,
			type: "single",
			answers: {
				a: "I take the lead",
				b: "We decide together",
				c: "I'm flexible and go with the flow",
				d: "I ask for reassurance before choosing",
			},
			answerKeys: ["a", "b", "c", "d"],
			active: true,
			createdAt: admin.firestore.FieldValue.serverTimestamp(),
		},

		// SECTION 4: LOVE & CONNECTION
		{
			id: "q_4_10",
			question: "How important is physical closeness (like hugs, kisses, intimacy)?",
			section: 4,
			sectionTitle: "LOVE & CONNECTION",
			sectionOrder: 1,
			questionOrder: 10,
			type: "single",
			answers: {
				a: "Very important",
				b: "Important, but not everything",
				c: "Depends on our emotional bond",
				d: "I prefer slow or less frequent intimacy",
			},
			answerKeys: ["a", "b", "c", "d"],
			active: true,
			createdAt: admin.firestore.FieldValue.serverTimestamp(),
		},
		{
			id: "q_4_11",
			question: "Rank your love languages from most important to least",
			section: 4,
			sectionTitle: "LOVE & CONNECTION",
			sectionOrder: 2,
			questionOrder: 11,
			type: "ranking",
			answers: {
				words: "Words of affirmation",
				touch: "Physical touch",
				time: "Quality time",
				service: "Acts of service",
				gifts: "Gifts giving",
			},
			answerKeys: ["words", "touch", "time", "service", "gifts"],
			active: true,
			createdAt: admin.firestore.FieldValue.serverTimestamp(),
		},
		{
			id: "q_4_12",
			question: "How do you usually show love?",
			section: 4,
			sectionTitle: "LOVE & CONNECTION",
			sectionOrder: 3,
			questionOrder: 12,
			type: "single",
			answers: {
				a: "Using words",
				b: "Showing physical affection",
				c: "Spending quality time",
				d: "Helping with tasks",
				e: "Giving gifts",
			},
			answerKeys: ["a", "b", "c", "d", "e"],
			active: true,
			createdAt: admin.firestore.FieldValue.serverTimestamp(),
		},

		// SECTION 5: LIFESTYLE & HABITS
		{
			id: "q_5_13",
			question: "Which activities fit you best? (Pick all)",
			section: 5,
			sectionTitle: "LIFESTYLE & HABITS",
			sectionOrder: 1,
			questionOrder: 13,
			type: "multi",
			answers: {
				workout: "Working out",
				cooking: "Cooking",
				art: "Art or creative things",
				reading: "Reading",
				traveling: "Traveling",
				outdoors: "Being outdoors",
				music: "Music",
				social: "Social events",
				quiet: "Quiet nights at home",
				helping: "Helping others",
				other: "Other",
			},
			answerKeys: ["workout", "cooking", "art", "reading", "traveling", "outdoors", "music", "social", "quiet", "helping", "other"],
			active: true,
			createdAt: admin.firestore.FieldValue.serverTimestamp(),
		},
		{
			id: "q_5_14",
			question: "What is your relationship with smoking/vaping?",
			section: 5,
			sectionTitle: "LIFESTYLE & HABITS",
			sectionOrder: 2,
			questionOrder: 14,
			type: "single",
			answers: {
				a: "I don't smoke or vape",
				b: "I don't, but I'm fine if my partner does",
				c: "I smoke/vape sometimes",
				d: "I smoke/vape regularly",
				e: "I prefer not to date someone who smokes",
			},
			answerKeys: ["a", "b", "c", "d", "e"],
			active: true,
			createdAt: admin.firestore.FieldValue.serverTimestamp(),
		},
		{
			id: "q_5_15",
			question: "How important is a partner's lifestyle to you?",
			section: 5,
			sectionTitle: "LIFESTYLE & HABITS",
			sectionOrder: 3,
			questionOrder: 15,
			type: "single",
			answers: {
				a: "Very important",
				b: "Somewhat important",
				c: "Not very important",
				d: "Not important",
			},
			answerKeys: ["a", "b", "c", "d"],
			active: true,
			createdAt: admin.firestore.FieldValue.serverTimestamp(),
		},

		// SECTION 6: PERSONALITY & CONNECTION STYLE
		{
			id: "q_6_16",
			question: "How would you describe your social energy?",
			section: 6,
			sectionTitle: "PERSONALITY & CONNECTION STYLE",
			sectionOrder: 1,
			questionOrder: 16,
			type: "single",
			answers: {
				a: "Mostly outgoing",
				b: "A mix of outgoing and quiet",
				c: "Mostly quiet",
			},
			answerKeys: ["a", "b", "c"],
			active: true,
			createdAt: admin.firestore.FieldValue.serverTimestamp(),
		},
		{
			id: "q_6_17",
			question: "What kind of partner fit feels best to you?",
			section: 6,
			sectionTitle: "PERSONALITY & CONNECTION STYLE",
			sectionOrder: 2,
			questionOrder: 17,
			type: "single",
			answers: {
				a: "Someone very similar to me",
				b: "Someone who balances me out",
				c: "A mix of same values but different traits",
				d: "I'm not sure, I go by the vibe",
			},
			answerKeys: ["a", "b", "c", "d"],
			active: true,
			createdAt: admin.firestore.FieldValue.serverTimestamp(),
		},
		{
			id: "q_6_18",
			question: "What is the MOST important trait in a long-term partner?",
			section: 6,
			sectionTitle: "PERSONALITY & CONNECTION STYLE",
			sectionOrder: 3,
			questionOrder: 18,
			type: "single",
			answers: {
				a: "Emotional Maturity: Someone who stays calm, listens, and communicates clearly.",
				b: "Drive and Direction: Someone who has goals and works toward their future.",
				c: "Warmth and Kindness: Someone who is caring, patient, and supportive.",
				d: "Fun and Positive Energy: Someone who brings joy, humor, and lightness.",
			},
			answerKeys: ["a", "b", "c", "d"],
			active: true,
			createdAt: admin.firestore.FieldValue.serverTimestamp(),
		},

		// SECTION 7: WHAT MATTERS MOST TO YOU
		{
			id: "q_7_19",
			question: "How important are these traits in a partner? (Rate 1–5)",
			section: 7,
			sectionTitle: "WHAT MATTERS MOST TO YOU",
			sectionOrder: 1,
			questionOrder: 19,
			type: "rating",
			answers: {
				emotional_intelligence: "Emotional intelligence",
				political_alignment: "Political alignment",
				physical_appearance: "Physical appearance",
				financial_stability: "Money/financial stability",
				communication_skills: "Communication skills",
				family_values: "Family values",
				spiritual_values: "Spiritual or religious values",
				lifestyle_match: "Lifestyle match",
			},
			answerKeys: ["emotional_intelligence", "political_alignment", "physical_appearance", "financial_stability", "communication_skills", "family_values", "spiritual_values", "lifestyle_match"],
			active: true,
			createdAt: admin.firestore.FieldValue.serverTimestamp(),
		},
	];

	try {
		// Step 1: Delete all existing questions
		console.log("Step 1: Deleting all existing questions...");
		const existingQuestions = await db
			.collection("PreferencesQuestions")
			.get();

		const batch1 = db.batch();
		let inactiveCount = 0;
		existingQuestions.docs.forEach((doc) => {
			batch1.delete(doc.ref);
			inactiveCount++;
		});
		await batch1.commit();
		console.log(`Deleted ${inactiveCount} existing questions`);

		// Step 2: Add new questions (in chunks of 10 for safety)
		console.log("Step 2: Adding 19 new questions...");
		const chunkSize = 10;
		for (let i = 0; i < newQuestions.length; i += chunkSize) {
			const chunk = newQuestions.slice(i, Math.min(i + chunkSize, newQuestions.length));
			const batch2 = db.batch();

			chunk.forEach((question) => {
				const docRef = db.collection("PreferencesQuestions").doc(question.id);
				batch2.set(docRef, question);
			});

			await batch2.commit();
			console.log(`Added ${chunk.length} questions (batch ${Math.floor(i / chunkSize) + 1})`);
		}

		// Step 3: Validation
		console.log("Step 3: Validating migration...");
		const validationSnapshot = await db
			.collection("PreferencesQuestions")
			.where("active", "==", true)
			.get();

		const validationErrors = [];
		const seenIds = new Set();

		validationSnapshot.docs.forEach((doc) => {
			const data = doc.data();

			// Check required fields
			if (!data.id || !data.question || !data.section || !data.type) {
				validationErrors.push(`Doc ${doc.id}: Missing required fields`);
			}

			// Check duplicate IDs
			if (seenIds.has(data.id)) {
				validationErrors.push(`Doc ${doc.id}: Duplicate question ID ${data.id}`);
			}
			seenIds.add(data.id);

			// Check valid type
			if (!["single", "multi", "ranking", "rating"].includes(data.type)) {
				validationErrors.push(`Doc ${doc.id}: Invalid type ${data.type}`);
			}
		});

		if (validationErrors.length > 0) {
			throw new Error(`Validation failed: ${validationErrors.join("; ")}`);
		}

		const successMsg = {
			success: true,
			message: `Migration completed successfully!`,
			stats: {
				inactiveCount,
				newQuestionsCount: newQuestions.length,
				validatedCount: validationSnapshot.docs.length,
				sections: 7,
			},
		};

		console.log(JSON.stringify(successMsg));
		return successMsg;
	} catch (error) {
		const errorMsg = `Migration failed: ${error.message}`;
		console.error(errorMsg);
		throw new functions.https.HttpsError("internal", errorMsg);
	}
});