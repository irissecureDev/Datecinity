# ⚡ QUICKSTART - Deploy PreferencesQuestions Refactor

**Temps estimé**: 30 minutes  
**Complexité**: Modérée  
**Risque**: Bas (une fois en production, peut être rollback)  

---

## 🟢 TL;DR (Résumé Exécutif)

1. **Deploy Cloud Function**: `firebase deploy --only functions`
2. **Run Migration**: Firebase Console → Cloud Functions → Execute
3. **Deploy App**: `flutter build apk && deploy`
4. **QA Test**: 2 users, complete profiles, check matching
5. **Done** ✅

---

## 📋 Dépendances Pré-requisites

- ✅ Firebase CLI: `firebase --version` (should be 13.0+)
- ✅ Flutter: `flutter --version` (should be 3.0+)
- ✅ Node.js: `node --version` (should be 20+)
- ✅ Git: `git --version`
- ✅ Access to: Firebase Console + Google Play Console

---

## 🚀 STEP 1: Deploy Cloud Function (5 minutes)

```bash
# Navigate to functions directory
cd /Users/macos/Desktop/IRIS\ SECURE/cheers/mobile-app/functions

# Test locally first (optional but recommended)
firebase emulators:start --only functions

# In another terminal, in another terminal:
# curl -X POST http://localhost:5001/[PROJECT]/us-central1/migratePreferencesQuestions

# Deploy to production
firebase deploy --only functions:migratePreferencesQuestions

# Result: Should see "✔ functions[migratePreferencesQuestions]: Successful"
```

---

## 📊 STEP 2: Execute Migration (5 minutes)

### Option A: Firebase Console (Easiest)
```
1. Open https://console.firebase.google.com
2. Select Project
3. Go to: Functions → migratePreferencesQuestions
4. Click "Testing" tab
5. Click "EXECUTE" button
6. Wait for result (should be <10 seconds)
7. See response: { success: true, stats: { newQuestionsCount: 19, ... } }
```

### Option B: Via gcloud CLI
```bash
gcloud functions call migratePreferencesQuestions \
  --region=us-central1 \
  --gen2
```

### Option C: Via curl
```bash
curl -X POST https://us-central1-[PROJECT_ID].cloudfunctions.net/migratePreferencesQuestions \
  -H "Content-Type: application/json" \
  -d '{"test": false}'
```

**Verify**: Go to Firestore Console → PreferencesQuestions → should see 19 documents

---

## 📱 STEP 3: Deploy Flutter App (10 minutes)

```bash
# Navigate to app root
cd /Users/macos/Desktop/IRIS\ SECURE/cheers/mobile-app

# Prepare
flutter clean
flutter pub get

# Verify no errors
flutter analyze

# Build
flutter build apk --release
# OR for iOS: flutter build ios --release

# Deploy
# Option 1: Direct APK (for testing)
#   - Upload to device via USB/ADB
#   - Or email APK link to testers

# Option 2: Google Play Store (beta track)
#   - Open Google Play Console
#   - Upload app bundle: build/app/outputs/bundle/release/app-release.aab
#   - Create "beta" track
#   - Add testers

# Option 3: Production (final)
#   - Same as Option 2, but select "production" track
#   - Requires app review (24-48 hours)
```

---

## ✅ STEP 4: QA Testing (10 minutes)

### Minimal Test (to verify core functionality)

**On Device 1 (User A)**:
```
1. Clear app data (Settings → Apps → cheers → Clear Storage)
2. Open app
3. Should see: "Complete Your Profile" button
4. Click → see CompleteProfileScreen with 7 tabs
5. Tab 1: See Q1, Q2, Q3, Q4 (single select)
6. Answer all 4 → click Tab 2
7. Tab 2: See Q5 (single), Q6 (single)
8. Answer both → click Tab 3
9. Tab 3: See Q7 (single), Q8 (single), Q9 (single)
10. Answer all → continue until Tab 7
11. Tab 7: See Q19 with 8 traits (rate 1-5 for each)
12. Rate all traits → click SAVE
13. See: "Profile updated successfully!"
14. Check Firestore: Users/[userA]/user_preferences should have q_1_1, q_1_2, etc.
```

**On Device 2 (User B)**:
```
Same as User A, BUT answer questions identically to User A
```

**Matching Test**:
```
On Device 1 (User A):
1. Go to Suggestions tab
2. Should see User B in list
3. Score should be: 95-100% (if answers identical)
4. Click → see MatchingBreakdownWidget with:
   - Overall: 95%+
   - Section 1: 100% (×20%)
   - Section 2: 100% (×15%)
   - ... all sections should be high
```

### Extended Test (if you have time)

**Different Answers Test**:
```
Device 1 (User A) → Answer opposite to User B
→ Matching score should drop to: 20-30%
→ Breakdown should show mismatches
```

**Ranking Test (Q11)**:
```
Device 1: Rank as: words(1), touch(2), time(3), service(4), gifts(5)
Device 2: Rank as: gifts(1), gifts(2), time(3), words(4), touch(5)
→ Matching for Q11 should be low (~20-30%)
```

**Multi-Select Test (Q13)**:
```
Device 1: Select: workout, reading, music
Device 2: Select: workout, movies, sports
→ Matching: 1 common item → Jaccard = 0.2 + bonus
```

**Rating Test (Q19)**:
```
Device 1: Rate emotional_intelligence=5, political_alignment=1
Device 2: Rate emotional_intelligence=4, political_alignment=5
→ Diff for emotional: 1 → score = 1 - (1/4) = 0.75
→ Diff for political: 4 → score = 1 - (4/4) = 0.0
```

---

## 🔍 VERIFICATION CHECKLIST

After deployment, verify:

- [ ] Cloud Function deployed successfully
- [ ] Migration executed (19 docs in Firestore)
- [ ] App builds without errors
- [ ] User A can complete profile
- [ ] User B can complete profile
- [ ] Answers stored in Firestore (correct format)
- [ ] Matching calculates (non-zero score)
- [ ] Score matches expected (identical answers ~95%+)
- [ ] No crashes in Crashlytics
- [ ] No warnings in Firebase Console

---

## ⚠️ COMMON ISSUES & FIXES

### Issue: "Cloud Function not found"
```
→ Run: firebase deploy --only functions:migratePreferencesQuestions
→ Verify in Console: Functions → list shows migratePreferencesQuestions
```

### Issue: "No questions available"
```
→ Run migration again (EXECUTE button)
→ Verify Firestore: PreferencesQuestions → 19 documents present
→ Refresh app cache: PreferencesQuestionsApi().clearCache()
```

### Issue: "App crashes on profile screen"
```
→ Check logs: flutter logs
→ Likely cause: Missing question in Firestore
→ Fix: Re-run migration, verify all 19 IDs present
```

### Issue: "Matching score is always 0.5"
```
→ Verify both users have answered all questions
→ Check format in Firestore: should be q_1_1, q_5_13, etc.
→ Not: preferences_1_1 or pref_1_1 (old format)
```

### Issue: "Save button not working"
```
→ Verify all 19 questions have answers (all tabs filled)
→ Check validation logs in flutter logs
→ Likely cause: 1 question missing answer
```

---

## 🎯 SUCCESS INDICATORS

✅ You're done when:
1. Firestore has 19 active questions
2. App deploys and runs
3. Users can complete profiles
4. Answers save to Firestore correctly
5. Matching calculates (80%+ for identical answers)
6. No crashes after 24 hours

---

## 🆘 Need Help?

**Code Issue**: Check IMPLEMENTATION_GUIDE.md  
**Deploy Issue**: Check DEPLOYMENT_GUIDE.md  
**Test Issue**: See VERIFICATION CHECKLIST above  
**General**: See PROJECT_SUMMARY.md  

---

**Version**: 1.0  
**Last Updated**: 18 mai 2026  
**Status**: ✅ READY TO DEPLOY
