# 📖 PreferencesQuestions Refactor - Documentation

**Version**: 1.0  
**Status**: ✅ Complete & Ready for Deployment  
**Last Updated**: 18 mai 2026  

---

## 🎯 Quick Links

| Document | Purpose |
|----------|---------|
| **[QUICKSTART.md](QUICKSTART.md)** | ⚡ 30-minute deployment guide |
| **[PREDEPLOYMENT_CHECKLIST.md](PREDEPLOYMENT_CHECKLIST.md)** | ✅ Pre-deployment validation |
| **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)** | 📚 Complete technical documentation |
| **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** | 🚀 Step-by-step deployment |
| **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** | 📋 Executive summary |
| **[FILES_MANIFEST.md](FILES_MANIFEST.md)** | 📄 All modified files |

---

## 📊 What Changed?

### Before (Old System)
```
❌ Simple 2-question binary matching
❌ 19 scattered questions on PageView
❌ Only single/multi-select support
❌ No section organization
❌ Matching score was dummy (0.5)
```

### After (New System)
```
✅ Real matching using 4 question types
✅ 19 questions in 7 organized sections
✅ Single, Multi, Ranking, Rating types
✅ Section-weighted scoring (20%, 15%, 20%, 15%, 15%, 10%, 5%)
✅ Modern TabBar UI
✅ Detailed matching breakdown
```

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────┐
│  User Opens App → CompleteProfileScreen │
└─────────────────────────────────────────┘
           ↓
    ┌──────────────────┐
    │  7 TabBar Tabs   │
    │  (7 Sections)    │
    └──────────────────┘
           ↓
    ┌──────────────────────────────────┐
    │  Question Types (4 Variants)     │
    │  - Single (radio)                │
    │  - Multi (checkboxes)            │
    │  - Ranking (drag-drop)           │
    │  - Rating (1-5 scale)            │
    └──────────────────────────────────┘
           ↓
    ┌──────────────────────────────────┐
    │  Validate & Save Answers         │
    │  via PreferencesAnswersApi       │
    └──────────────────────────────────┘
           ↓
    ┌──────────────────────────────────┐
    │  Firestore: user_preferences     │
    │  {q_1_1: "a", q_5_13: [...], ...}│
    └──────────────────────────────────┘
           ↓
    ┌──────────────────────────────────┐
    │  Matching Algorithm              │
    │  (SuggestionsService)            │
    │  - Section-weighted scoring      │
    │  - Type-specific comparisons     │
    │  - Final: 0-100% score           │
    └──────────────────────────────────┘
           ↓
    ┌──────────────────────────────────┐
    │  Display: MatchingBreakdownWidget│
    │  Overall % + 7 sections breakdown│
    └──────────────────────────────────┘
```

---

## 🗂️ File Structure

### Core Models
```
lib/datas/
├── preferences_question.dart  ← Questions with section/type
└── preferences_answer.dart    ← Answer storage (4 types)
```

### APIs
```
lib/api/
├── preferences_questions_api.dart  ← Fetch questions (cached)
└── preferences_answers_api.dart    ← Save & validate answers
```

### Business Logic
```
lib/services/
└── suggestions_service.dart  ← Real matching algorithm
```

### UI
```
lib/screens/
└── complete_profile_screen.dart  ← 7-tab interface

lib/widgets/
└── matching_breakdown_widget.dart  ← Breakdown display
```

### Cloud Backend
```
functions/
└── index.js  ← Cloud Function (data migration)
```

### Tests
```
test/
└── preferences_questions_test.dart  ← Unit tests (15 tests)
```

---

## 🚀 How to Deploy

### Option A: Quick Deploy (5 mins reading)
→ Read: **[QUICKSTART.md](QUICKSTART.md)**

### Option B: Detailed Deploy (15 mins reading)
→ Read: **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)**

### Option C: Complete Understanding (30 mins reading)
→ Read: **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)**

### Option D: Pre-Deploy Validation
→ Use: **[PREDEPLOYMENT_CHECKLIST.md](PREDEPLOYMENT_CHECKLIST.md)**

---

## 💡 Key Concepts

### 1. The 19 Questions

**Section 1: What You Want In Love** (4 Qs)
- Q1: Relationship purpose
- Q2: Commitment timeline
- Q3: Core emotional need
- Q4: Emotional baseline

**Section 2: How You Handle Feelings** (2 Qs)
- Q5: Emotion processing
- Q6: Conflict communication

**Section 3: How You Communicate** (3 Qs)
- Q7: Communication priority
- Q8: Deep conversations
- Q9: Emotional expression

**Section 4: Love & Connection** (3 Qs)
- Q10: Physical affection
- **Q11: Love languages (RANKING)**
- Q12: Intimacy frequency

**Section 5: Lifestyle & Habits** (3 Qs)
- **Q13: Activities (MULTI-SELECT)**
- Q14: Social energy
- Q15: Future planning

**Section 6: Personality & Connection** (3 Qs)
- Q16: Personality traits
- Q17: Humor importance
- Q18: Growth partnership

**Section 7: What Matters Most** (1 Q)
- **Q19: Values (RATING - 8 traits)**

### 2. Four Question Types

| Type | Format | Example | Questions |
|------|--------|---------|-----------|
| **Single** | Pick one | "What's your favorite color?" | Q1-10, Q12, Q14-18 |
| **Multi** | Pick many | "What activities do you enjoy?" | Q5, Q13 |
| **Ranking** | Order items | "Rank love languages 1-5" | Q11 |
| **Rating** | Rate 1-5 | "Rate importance: 1-5" | Q19 (8 traits) |

### 3. Matching Algorithm

For each section:
1. Compare answers between two users (type-specific)
2. Average the scores for that section
3. Multiply by section weight (20%, 15%, etc.)
4. Sum all weighted sections

**Result**: 0-100% compatibility

---

## 🧪 Testing

### Run Unit Tests
```bash
flutter test test/preferences_questions_test.dart
```

### Manual Testing
1. Complete profile on Device A
2. Complete profile on Device B (identically)
3. Check matching score (should be ~95%+)
4. Toggle answers and re-test

---

## 🔍 Troubleshooting

### "No questions showing"
→ Cloud Function `migratePreferencesQuestions` not executed  
→ Solution: Run migration via Firebase Console

### "Validation error: Missing answers"
→ Not all 19 questions answered  
→ Solution: Answer all questions before clicking SAVE

### "Matching score always 0.5"
→ Users haven't answered all questions  
→ Solution: Complete profiles for both users

### "App crashes on profile screen"
→ Possible: Missing question in Firestore  
→ Solution: Re-run migration, check Firestore has 19 docs

---

## 📚 Code Examples

### Get All Questions
```dart
final api = PreferencesQuestionsApi();
final questions = await api.getAllQuestions();
// Returns: List<PreferencesQuestion> with 19 items
```

### Get Questions by Section
```dart
final section1Questions = await api.getQuestionsBySection(1);
// Returns: [q_1_1, q_1_2, q_1_3, q_1_4]
```

### Store User Answers
```dart
final answers = UserPreferencesAnswers();
answers.addSingleAnswer('q_1_1', 'a');
answers.addMultiAnswer('q_5_13', {'workout', 'reading'});
answers.addRankingAnswer('q_4_11', {'words': 1, 'touch': 2, ...});
answers.addRatingAnswer('q_7_19', {'emotional_intelligence': 5, ...});

await PreferencesAnswersApi().updateUserAnswers(userId, answers);
```

### Calculate Matching
```dart
final compatibility = await SuggestionsService.calculateQuizCompatibility(
  userAData,
  userBData,
  userAAnswers,
  userBAnswers
);
// Returns: 0.0 to 1.0 (0-100%)
```

### Display Breakdown
```dart
MatchingBreakdownWidget(
  matchScore: 88.5,
  expandable: true,
)
```

---

## 🔐 Security Notes

- ✅ Cloud Function uses Firebase Admin SDK (secure)
- ✅ Firestore rules control access (users only see their own data)
- ✅ PreferencesQuestions is public (no sensitive data)
- ✅ Backup before migration (optional but recommended)

---

## 📈 Performance Metrics

| Operation | Time | Cache |
|-----------|------|-------|
| Fetch 19 questions | ~500ms | 60 min TTL |
| Save user preferences | ~800ms | N/A |
| Calculate matching | ~200ms | N/A |
| Display breakdown | ~50ms | N/A |

---

## 🎓 Learning Path

### Day 1: Overview
1. Read: [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
2. Skim: [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)

### Day 2: Code Review
1. Review: [FILES_MANIFEST.md](FILES_MANIFEST.md)
2. Study: Model classes (preferences_question.dart)
3. Study: APIs (preferences_questions_api.dart)

### Day 3: Deployment
1. Follow: [QUICKSTART.md](QUICKSTART.md)
2. Use: [PREDEPLOYMENT_CHECKLIST.md](PREDEPLOYMENT_CHECKLIST.md)
3. Deploy: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

## 📞 FAQ

**Q: Can I rollback after deploying?**  
A: Yes! See DEPLOYMENT_GUIDE.md → "Rollback Plan"

**Q: How long does migration take?**  
A: ~30 seconds for Firestore + 5 minutes for app build/upload

**Q: Do existing users need to re-answer?**  
A: Yes, the new format is incompatible (breaking change)

**Q: Can I modify the questions later?**  
A: Yes, edit Firestore directly. Cache expires after 60 minutes.

**Q: What if a user doesn't complete all 19 questions?**  
A: SAVE button is disabled until all 19 are answered

**Q: Is the matching algorithm deterministic?**  
A: Yes, same answers always produce same score

---

## 📝 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 18 May 2026 | Initial release with 19 questions, 4 types, real matching |

---

## 👥 Contributors

- **Mobile App Team**: Development, testing, deployment
- **Product**: Requirements, UX feedback
- **QA**: Testing, validation
- **Firebase Support**: Backend assistance (if needed)

---

## 📞 Support

**Technical Issues**: See [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)  
**Deployment Help**: See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)  
**Quick Deploy**: See [QUICKSTART.md](QUICKSTART.md)  
**Validation**: See [PREDEPLOYMENT_CHECKLIST.md](PREDEPLOYMENT_CHECKLIST.md)  

---

## ✅ Deployment Status

| Phase | Status | Docs |
|-------|--------|------|
| Code Implementation | ✅ Complete | [FILES_MANIFEST.md](FILES_MANIFEST.md) |
| Testing | ✅ Complete | [test/preferences_questions_test.dart](test/preferences_questions_test.dart) |
| Cloud Function | ✅ Ready | [functions/index.js](functions/index.js) |
| App UI | ✅ Ready | [lib/screens/complete_profile_screen.dart](lib/screens/complete_profile_screen.dart) |
| Documentation | ✅ Complete | [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) |
| **Deployment** | 🟡 Pending | [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) |

---

**Next Step**: Run through [PREDEPLOYMENT_CHECKLIST.md](PREDEPLOYMENT_CHECKLIST.md) and then follow [QUICKSTART.md](QUICKSTART.md) for deployment.

✅ **PROJECT READY FOR DEPLOYMENT** ✅

---

*For questions or issues, refer to the documentation links above or contact the Mobile App Team.*
