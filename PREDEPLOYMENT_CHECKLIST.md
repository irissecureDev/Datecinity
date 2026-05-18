# ✅ Pré-Déploiement Checklist - PreferencesQuestions Refactor

**Date**: 18 mai 2026  
**Version**: 1.0  
**Status**: READY FOR DEPLOYMENT ✅  

Utilisez cette checklist avant de déployer en production.

---

## 🔧 Code Quality (5 minutes)

### Compilation & Analysis
- [ ] `flutter analyze` - Pas d'erreurs/warnings
  ```bash
  cd /Users/macos/Desktop/IRIS\ SECURE/cheers/mobile-app
  flutter analyze
  ```
  Expected: "No issues found!"

- [ ] `flutter test` - Tous les tests passent
  ```bash
  flutter test test/preferences_questions_test.dart
  ```
  Expected: "All tests passed! (15 tests)"

- [ ] Cloud Function syntax OK
  ```bash
  cd functions && npm run lint
  ```
  Expected: No lint errors

- [ ] No TODO/FIXME comments in active code
  - Check: `grep -r "TODO\|FIXME" lib/`
  - Should return: 0 results (or only in comments)

### Code Review
- [ ] PreferencesQuestion model: All fields present
  - section, sectionTitle, sectionOrder, type, answerKeys ✓
- [ ] PreferencesAnswer model: All 4 maps initialized
  - singleAnswers, multiAnswers, rankingAnswers, ratingAnswers ✓
- [ ] PreferencesQuestionsApi: Cache logic correct
  - TTL = 60 minutes ✓
- [ ] PreferencesAnswersApi: Validation complete
  - Single/Multi/Ranking/Rating validators ✓
- [ ] SuggestionsService: Matching weights correct
  - Section weights: 20%, 15%, 20%, 15%, 15%, 10%, 5% = 100% ✓
- [ ] CompleteProfileScreen: All 4 UI types present
  - Single (Q1-10, Q12, Q14-18) ✓
  - Multi (Q5, Q13) ✓
  - Ranking (Q11) ✓
  - Rating (Q19) ✓
- [ ] MatchingBreakdownWidget: 7 sections mapped
  - Icons, titles, descriptions all present ✓

---

## 🗄️ Data Validation (5 minutes)

### Firestore Structure
- [ ] PreferencesQuestions collection exists (empty, ready for migration)
- [ ] Questions have required fields:
  - id, question, section, sectionTitle, sectionOrder, questionOrder, type, answers, answerKeys, active

### Cloud Function Data
- [ ] 19 questions defined in functions/index.js
  - Q1-4 (Section 1) ✓
  - Q5-6 (Section 2) ✓
  - Q7-9 (Section 3) ✓
  - Q10-12 (Section 4) ✓
  - Q13-15 (Section 5) ✓
  - Q16-18 (Section 6) ✓
  - Q19 (Section 7) ✓
- [ ] All question types correct:
  - Single: Q1-10, Q12, Q14-18 ✓
  - Multi: Q5, Q13 ✓
  - Ranking: Q11 ✓
  - Rating: Q19 ✓
- [ ] Answer keys match display order
  - No typos, no missing keys
- [ ] No duplicate question IDs
  - `grep "id.*q_" functions/index.js | sort | uniq -d` → 0 results

---

## 📱 App Readiness (5 minutes)

### Build & Release
- [ ] Clean build successful
  ```bash
  flutter clean && flutter pub get && flutter build apk --release
  ```
  Expected: "Built to: build/app/outputs/apk/release/app-release.apk"

- [ ] No runtime errors in logs
  ```bash
  flutter logs | head -20  # During build
  ```
  Expected: No ERROR logs

- [ ] App starts without crashes
  - Test on emulator/device for 30 seconds
  - No Crashlytics reports

- [ ] Storage & permissions OK
  - App has Firestore read/write permission
  - No permission errors in logs

### UI/UX Verification
- [ ] CompleteProfileScreen loads
  - [ ] See 7 tabs
  - [ ] Tabs labeled correctly (What You Want, How You Handle, etc.)
- [ ] All question types render
  - [ ] Q1 (single): Radio options visible
  - [ ] Q13 (multi): Checkboxes visible
  - [ ] Q11 (ranking): Drag handles visible
  - [ ] Q19 (rating): 1-5 buttons visible

---

## ☁️ Cloud Setup (5 minutes)

### Firebase Project
- [ ] Firebase CLI installed & configured
  ```bash
  firebase --version  # Should be 13.0+
  firebase login
  firebase list  # See projects
  ```

- [ ] Firestore database exists
  - Firebase Console → Firestore → Rules set to allow deployment

- [ ] Cloud Functions enabled
  - Firebase Console → Functions → Enabled

- [ ] PreferencesQuestions collection created (empty)
  - Firebase Console → Firestore → Collections

### Project Credentials
- [ ] `firebase.json` configured
- [ ] `google-services.json` in app/
- [ ] `GoogleService-Info.plist` in ios/ (if iOS)
- [ ] `.env` or credentials file (if needed)

---

## 🧪 Testing Scenario (10 minutes)

### Manual Test (on device/emulator)

**Setup**:
- [ ] Fresh install (clear all data if re-testing)
- [ ] 2 devices/emulators ready

**Test A - Profile Completion**:
- [ ] Device 1: Open app → Complete Profile visible
- [ ] Click CompleteProfileScreen
- [ ] See TabBar with 7 tabs
- [ ] Tab 1 (What You Want):
  - [ ] Q1: Select option → visible
  - [ ] Q2: Select option → visible
  - [ ] Q3: Select option → visible
  - [ ] Q4: Select option → visible
- [ ] Tab 2 (How You Handle):
  - [ ] Q5: Select single option
  - [ ] Q6: Select single option
- [ ] Tab 3 (Communication):
  - [ ] Q7, Q8, Q9: Select options
- [ ] Tab 4 (Intimacy):
  - [ ] Q10, Q12: Select options
  - [ ] Q11 RANKING: Drag items to reorder (verify order changes)
- [ ] Tab 5 (Lifestyle):
  - [ ] Q14, Q15: Select options
  - [ ] Q13 MULTI: Select 3+ items (verify all checkable)
- [ ] Tab 6 (Personality):
  - [ ] Q16, Q17, Q18: Select options
- [ ] Tab 7 (Values):
  - [ ] Q19 RATING: Rate 1-5 for 8 traits
  - [ ] All traits must be rated before SAVE enabled
- [ ] Click SAVE
  - [ ] Modal: "Profile updated successfully!"
  - [ ] Return to previous screen

**Test B - Firestore Verification**:
- [ ] Firebase Console → Firestore → Users/{deviceUserId}/user_preferences
- [ ] Verify fields:
  - [ ] q_1_1: "a" (string)
  - [ ] q_5_13: ["item1", "item2"] (array)
  - [ ] q_4_11: {words: 1, touch: 2, ...} (object with ranking)
  - [ ] q_7_19_emotional_intelligence: 5 (number 1-5)
  - [ ] All other q_7_19_* fields present (8 traits)

**Test C - Matching (2 Devices)**:
- [ ] Device 1 & 2: Both complete profiles identically
- [ ] Device 1: Go to Suggestions
- [ ] See Device 2 in list
- [ ] Matching score: 95-100% (should be very high)
- [ ] Click breakdown:
  - [ ] Overall: 95%+
  - [ ] All sections: 80%+ (matching answers)
  - [ ] Section weights shown

**Test D - Opposite Answers**:
- [ ] Device 1: Go back, update profile (opposite answers)
- [ ] Device 1: Suggestions screen re-loads
- [ ] Matching score drops to: 10-30% (should be low)
- [ ] Breakdown shows low scores per section

### Expected Results ✅
- Profile saves without errors
- Firestore structure correct
- Matching scores are reasonable
- No crashes in Crashlytics

---

## 📊 Performance Check (5 minutes)

### App Performance
- [ ] Tab switching: < 500ms (smooth)
- [ ] Question load: < 1s
- [ ] Save submission: < 2s
- [ ] Matching calc: < 1s per pair
- [ ] Memory usage: Stable (no leaks)

### Network Performance
- [ ] Firestore fetch: < 2s
- [ ] Cloud Function execution: < 5s
- [ ] No timeout errors

### UI Responsiveness
- [ ] No lag during drag-drop (Q11)
- [ ] No jank during tab switching
- [ ] Smooth animations
- [ ] Responsive buttons

---

## 🔐 Security Validation (5 minutes)

### Firebase Rules
- [ ] Firestore rules reviewed
  - [ ] Only authenticated users can write preferences
  - [ ] Users can only access their own data
  - [ ] PreferencesQuestions collection is readable by all (no sensitive data)

### Data Privacy
- [ ] No sensitive data in PreferencesQuestions (OK to expose)
- [ ] User preferences stored in `Users/{id}/user_preferences` (private)
- [ ] No secrets in code (API keys, etc.)
- [ ] No credentials in git

### API Security
- [ ] Cloud Function requires authentication (if applicable)
- [ ] Migration function protected from unauthorized calls

---

## 📦 Deployment Preparation (5 minutes)

### Files Ready
- [ ] All code changes committed to git
  ```bash
  git status  # Should be clean
  git log --oneline | head -5  # See recent commits
  ```

- [ ] Version bumped (if needed)
  ```bash
  cat pubspec.yaml | grep "^version:"
  ```

- [ ] Changelog updated (if you maintain one)
  - Document: "Added 19-question preference system"

### Release Artifacts
- [ ] APK built & tested
  - [ ] File exists: `build/app/outputs/apk/release/app-release.apk`
  - [ ] Signed (for production)
- [ ] App Bundle built (for Play Store)
  - [ ] File exists: `build/app/outputs/bundle/release/app-release.aab`

### Documentation
- [ ] IMPLEMENTATION_GUIDE.md ✓ (Created)
- [ ] DEPLOYMENT_GUIDE.md ✓ (Created)
- [ ] QUICKSTART.md ✓ (Created)
- [ ] PROJECT_SUMMARY.md ✓ (Created)
- [ ] FILES_MANIFEST.md ✓ (Created)

---

## 🚀 Deployment Steps (Checklist)

**Phase 1: Backend**
- [ ] Step 1: Deploy Cloud Function
  ```bash
  firebase deploy --only functions:migratePreferencesQuestions
  ```
  Expected: "✔ functions[...]: Successful"

- [ ] Step 2: Execute Migration
  - Firebase Console → Cloud Functions → Execute
  - Expected: stats { newQuestionsCount: 19 }

- [ ] Step 3: Verify Firestore
  - Firestore Console → PreferencesQuestions
  - Expected: 19 documents visible

**Phase 2: Frontend**
- [ ] Step 4: Deploy App
  - Build: `flutter build apk --release`
  - Upload to Play Store (beta track)
  - Expected: Build successful

- [ ] Step 5: QA Testing
  - Send to 5-10 internal testers
  - Expected: No crashes, all features work

- [ ] Step 6: Production Release
  - Promote from beta to production
  - Expected: Gradual rollout (10% → 50% → 100%)

---

## ❌ Rollback Readiness

- [ ] Firebase backup created (optional but recommended)
  ```bash
  gcloud firestore export gs://YOUR_BUCKET/backup_$(date +%Y%m%d_%H%M%S)
  ```

- [ ] Previous app version available in Play Store
  - Ability to revert to previous APK

- [ ] Rollback procedure documented
  - See DEPLOYMENT_GUIDE.md → "Rollback Plan"

- [ ] Team notified of rollback triggers
  - >100 crashes in 24h
  - User data corruption
  - Major functionality broken

---

## 📞 Pre-Deployment Communication

- [ ] Team notified of deployment window
  - Date & time (e.g., Tuesday 2 AM UTC)
  - Expected downtime: <5 minutes

- [ ] Support team briefed on changes
  - New preference system = users must re-complete profiles
  - Matching now uses real preference data

- [ ] Users/QA informed (if applicable)
  - "Update your profile preferences" message
  - Feature release notes prepared

---

## ✨ Final Sign-Off

**Pre-Deployment Verification**:
- [ ] All checklist items completed
- [ ] No blocking issues
- [ ] Team approves release
- [ ] Go/No-Go decision made

**Approved by**:
- [ ] Tech Lead: _________________ Date: _______
- [ ] Product Owner: _____________ Date: _______
- [ ] QA Lead: ___________________ Date: _______

**Deployment Authorized**: ✅ YES / ❌ NO

---

## 🎯 Success Criteria (Post-Deployment)

**Immediate (First Hour)**:
- ✅ Cloud Function deployed
- ✅ 19 questions in Firestore
- ✅ App builds successfully
- ✅ No crash spike in Crashlytics

**Short Term (24 Hours)**:
- ✅ Users complete profiles without errors
- ✅ Answers save to Firestore correctly
- ✅ Matching calculates for user pairs
- ✅ No data corruption reports

**Medium Term (1 Week)**:
- ✅ Stable user adoption
- ✅ Matching accuracy verified
- ✅ Performance acceptable
- ✅ No major issues

---

**Checklist Version**: 1.0  
**Last Updated**: 18 mai 2026  
**Status**: Ready for Deployment ✅

---

**Print & Use**: Print this page before deployment or use digital copy for check-off.
