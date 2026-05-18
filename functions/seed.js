/**
 * One-time seed script — run with: node seed.js
 * Deletes all existing PreferencesQuestions and inserts 19 new ones.
 * Requires: firebase-admin (already in functions/package.json)
 * Auth: uses GOOGLE_APPLICATION_CREDENTIALS or firebase CLI default credentials
 */

const admin = require('firebase-admin');
const path = require('path');

const keyPath = process.argv[2];
if (!keyPath) {
    console.error('❌ Usage: node seed.js /path/to/serviceAccountKey.json');
    process.exit(1);
}

const serviceAccount = require(path.resolve(keyPath));

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'soulemate-e3cc5',
});

const db = admin.firestore();

const questions = [
    // ─── SECTION 1: WHAT YOU WANT IN LOVE ────────────────────────────
    {
        id: 'q_1_1',
        question: 'What do you want a relationship to be in your life?',
        section: 1, sectionTitle: 'WHAT YOU WANT IN LOVE', sectionOrder: 1, questionOrder: 1, order: 1,
        type: 'single',
        answers: {
            a: 'A place that supports me while I grow',
            b: 'A team where we build a life together',
            c: 'A close and deep emotional bond',
            d: 'Something natural that grows without pressure',
        },
        answerKeys: ['a', 'b', 'c', 'd'],
        active: true,
    },
    {
        id: 'q_1_2',
        question: 'How do you feel about having kids in the future?',
        section: 1, sectionTitle: 'WHAT YOU WANT IN LOVE', sectionOrder: 2, questionOrder: 2, order: 2,
        type: 'single',
        answers: {
            a: 'I want kids',
            b: 'Yes, but later',
            c: "I'm not sure",
            d: "I don't want kids",
            e: "I'm open to someone who already has kids",
        },
        answerKeys: ['a', 'b', 'c', 'd', 'e'],
        active: true,
    },
    {
        id: 'q_1_3',
        question: 'What do you hope to create with a partner?',
        section: 1, sectionTitle: 'WHAT YOU WANT IN LOVE', sectionOrder: 3, questionOrder: 3, order: 3,
        type: 'single',
        answers: {
            a: 'A family',
            b: 'A stable life with shared goals',
            c: 'Fun adventures and new experiences',
            d: 'Personal growth and emotional support',
        },
        answerKeys: ['a', 'b', 'c', 'd'],
        active: true,
    },
    {
        id: 'q_1_4',
        question: 'What dating pace feels right for you?',
        section: 1, sectionTitle: 'WHAT YOU WANT IN LOVE', sectionOrder: 4, questionOrder: 4, order: 4,
        type: 'single',
        answers: {
            a: 'Slow and steady',
            b: 'Natural and comfortable',
            c: 'Fast connection',
            d: 'It depends on our chemistry',
        },
        answerKeys: ['a', 'b', 'c', 'd'],
        active: true,
    },

    // ─── SECTION 2: HOW YOU HANDLE FEELINGS ──────────────────────────
    {
        id: 'q_2_5',
        question: 'When you feel upset in a relationship, what do you usually do?',
        section: 2, sectionTitle: 'HOW YOU HANDLE FEELINGS', sectionOrder: 1, questionOrder: 5, order: 5,
        type: 'single',
        answers: {
            a: 'I need space to think',
            b: 'I want comfort or reassurance',
            c: 'I talk about how I feel',
            d: 'I shut down or try to distract myself',
        },
        answerKeys: ['a', 'b', 'c', 'd'],
        active: true,
    },
    {
        id: 'q_2_6',
        question: 'How much alone time do you like in a relationship?',
        section: 2, sectionTitle: 'HOW YOU HANDLE FEELINGS', sectionOrder: 2, questionOrder: 6, order: 6,
        type: 'single',
        answers: {
            a: 'A lot — I like space',
            b: 'A balance of space and closeness',
            c: 'I like talking and connecting every day',
            d: 'It depends on the partner',
        },
        answerKeys: ['a', 'b', 'c', 'd'],
        active: true,
    },

    // ─── SECTION 3: HOW YOU COMMUNICATE ──────────────────────────────
    {
        id: 'q_3_7',
        question: 'How do you act during disagreements?',
        section: 3, sectionTitle: 'HOW YOU COMMUNICATE', sectionOrder: 1, questionOrder: 7, order: 7,
        type: 'single',
        answers: {
            a: 'I stay calm and try to solve it',
            b: 'I get emotional but want things to work out',
            c: 'I shut down or avoid talking',
            d: 'I feel strong emotions but want clarity',
        },
        answerKeys: ['a', 'b', 'c', 'd'],
        active: true,
    },
    {
        id: 'q_3_8',
        question: 'How do you prefer to fix problems?',
        section: 3, sectionTitle: 'HOW YOU COMMUNICATE', sectionOrder: 2, questionOrder: 8, order: 8,
        type: 'single',
        answers: {
            a: 'I talk about it right away.',
            b: 'I need some space to calm down first.',
            c: 'I need time to understand my feelings before I talk.',
            d: 'I wait until it feels safe or really needed.',
        },
        answerKeys: ['a', 'b', 'c', 'd'],
        active: true,
    },
    {
        id: 'q_3_9',
        question: 'How do you make decisions with a partner?',
        section: 3, sectionTitle: 'HOW YOU COMMUNICATE', sectionOrder: 3, questionOrder: 9, order: 9,
        type: 'single',
        answers: {
            a: 'I take the lead',
            b: 'We decide together',
            c: "I'm flexible and go with the flow",
            d: 'I ask for reassurance before choosing',
        },
        answerKeys: ['a', 'b', 'c', 'd'],
        active: true,
    },

    // ─── SECTION 4: LOVE & CONNECTION ────────────────────────────────
    {
        id: 'q_4_10',
        question: 'How important is physical closeness (like hugs, kisses, intimacy)?',
        section: 4, sectionTitle: 'LOVE & CONNECTION', sectionOrder: 1, questionOrder: 10, order: 10,
        type: 'single',
        answers: {
            a: 'Very important',
            b: 'Important, but not everything',
            c: 'Depends on our emotional bond',
            d: 'I prefer slow or less frequent intimacy',
        },
        answerKeys: ['a', 'b', 'c', 'd'],
        active: true,
    },
    {
        id: 'q_4_11',
        question: 'Rank your love languages from most important to least',
        section: 4, sectionTitle: 'LOVE & CONNECTION', sectionOrder: 2, questionOrder: 11, order: 11,
        type: 'ranking',
        answers: {
            words: 'Words of affirmation',
            touch: 'Physical touch',
            time: 'Quality time',
            service: 'Acts of service',
            gifts: 'Gifts giving',
        },
        answerKeys: ['words', 'touch', 'time', 'service', 'gifts'],
        active: true,
    },
    {
        id: 'q_4_12',
        question: 'How do you usually show love?',
        section: 4, sectionTitle: 'LOVE & CONNECTION', sectionOrder: 3, questionOrder: 12, order: 12,
        type: 'single',
        answers: {
            a: 'Using words',
            b: 'Showing physical affection',
            c: 'Spending quality time',
            d: 'Helping with tasks',
            e: 'Giving gifts',
        },
        answerKeys: ['a', 'b', 'c', 'd', 'e'],
        active: true,
    },

    // ─── SECTION 5: LIFESTYLE & HABITS ───────────────────────────────
    {
        id: 'q_5_13',
        question: 'Which activities fit you best? (Pick all that apply)',
        section: 5, sectionTitle: 'LIFESTYLE & HABITS', sectionOrder: 1, questionOrder: 13, order: 13,
        type: 'multi',
        answers: {
            workout: 'Working out',
            cooking: 'Cooking',
            art: 'Art or creative things',
            reading: 'Reading',
            traveling: 'Traveling',
            outdoors: 'Being outdoors',
            music: 'Music',
            social: 'Social events',
            quiet: 'Quiet nights at home',
            helping: 'Helping others',
            other: 'Other',
        },
        answerKeys: ['workout', 'cooking', 'art', 'reading', 'traveling', 'outdoors', 'music', 'social', 'quiet', 'helping', 'other'],
        active: true,
    },
    {
        id: 'q_5_14',
        question: 'What is your relationship with smoking/vaping?',
        section: 5, sectionTitle: 'LIFESTYLE & HABITS', sectionOrder: 2, questionOrder: 14, order: 14,
        type: 'single',
        answers: {
            a: "I don't smoke or vape",
            b: "I don't, but I'm fine if my partner does",
            c: 'I smoke/vape sometimes',
            d: 'I smoke/vape regularly',
            e: 'I prefer not to date someone who smokes',
        },
        answerKeys: ['a', 'b', 'c', 'd', 'e'],
        active: true,
    },
    {
        id: 'q_5_15',
        question: "How important is a partner's lifestyle to you?",
        section: 5, sectionTitle: 'LIFESTYLE & HABITS', sectionOrder: 3, questionOrder: 15, order: 15,
        type: 'single',
        answers: {
            a: 'Very important',
            b: 'Somewhat important',
            c: 'Not very important',
            d: 'Not important',
        },
        answerKeys: ['a', 'b', 'c', 'd'],
        active: true,
    },

    // ─── SECTION 6: PERSONALITY & CONNECTION STYLE ───────────────────
    {
        id: 'q_6_16',
        question: 'How would you describe your social energy?',
        section: 6, sectionTitle: 'PERSONALITY & CONNECTION STYLE', sectionOrder: 1, questionOrder: 16, order: 16,
        type: 'single',
        answers: {
            a: 'Mostly outgoing',
            b: 'A mix of outgoing and quiet',
            c: 'Mostly quiet',
        },
        answerKeys: ['a', 'b', 'c'],
        active: true,
    },
    {
        id: 'q_6_17',
        question: 'What kind of partner fit feels best to you?',
        section: 6, sectionTitle: 'PERSONALITY & CONNECTION STYLE', sectionOrder: 2, questionOrder: 17, order: 17,
        type: 'single',
        answers: {
            a: 'Someone very similar to me',
            b: 'Someone who balances me out',
            c: 'A mix of same values but different traits',
            d: "I'm not sure, I go by the vibe",
        },
        answerKeys: ['a', 'b', 'c', 'd'],
        active: true,
    },
    {
        id: 'q_6_18',
        question: 'What is the MOST important trait in a long-term partner?',
        section: 6, sectionTitle: 'PERSONALITY & CONNECTION STYLE', sectionOrder: 3, questionOrder: 18, order: 18,
        type: 'single',
        answers: {
            a: 'Emotional Maturity: Someone who stays calm, listens, and communicates clearly.',
            b: 'Drive and Direction: Someone who has goals and works toward their future.',
            c: 'Warmth and Kindness: Someone who is caring, patient, and supportive.',
            d: 'Fun and Positive Energy: Someone who brings joy, humor, and lightness.',
        },
        answerKeys: ['a', 'b', 'c', 'd'],
        active: true,
    },

    // ─── SECTION 7: WHAT MATTERS MOST TO YOU ─────────────────────────
    {
        id: 'q_7_19',
        question: 'How important are these traits in a partner? (Rate 1–5)',
        section: 7, sectionTitle: 'WHAT MATTERS MOST TO YOU', sectionOrder: 1, questionOrder: 19, order: 19,
        type: 'rating',
        answers: {
            emotional_intelligence: 'Emotional intelligence',
            political_alignment: 'Political alignment',
            physical_appearance: 'Physical appearance',
            financial_stability: 'Money/financial stability',
            communication_skills: 'Communication skills',
            family_values: 'Family values',
            spiritual_values: 'Spiritual or religious values',
            lifestyle_match: 'Lifestyle match',
        },
        answerKeys: [
            'emotional_intelligence', 'political_alignment', 'physical_appearance',
            'financial_stability', 'communication_skills', 'family_values',
            'spiritual_values', 'lifestyle_match',
        ],
        active: true,
    },
];

async function seed() {
    console.log('🗑️  Deleting existing questions...');
    const existing = await db.collection('PreferencesQuestions').get();
    const deleteBatch = db.batch();
    existing.docs.forEach((doc) => deleteBatch.delete(doc.ref));
    await deleteBatch.commit();
    console.log(`   Deleted ${existing.docs.length} documents.`);

    console.log('✍️  Inserting 19 new questions...');
    const insertBatch = db.batch();
    questions.forEach((q) => {
        const ref = db.collection('PreferencesQuestions').doc(q.id);
        insertBatch.set(ref, q);
    });
    await insertBatch.commit();
    console.log(`   Inserted ${questions.length} questions across 7 sections.`);

    console.log('✅ Done!');
    process.exit(0);
}

seed().catch((err) => {
    console.error('❌ Error:', err);
    process.exit(1);
});
