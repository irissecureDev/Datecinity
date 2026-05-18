# 🚀 Guide de Déploiement - PreferencesQuestions Refactor

**Version**: 1.0  
**Date**: 18 mai 2026  
**Équipe**: Mobile App  
**Durée estimée**: 30 minutes

---

## 📋 Pré-déploiement Checklist

### Validations Code
- [x] Cloud Function compilée et testée localement
- [x] Dart code sans erreurs de compilation
- [x] Tests unitaires créés et valides
- [x] Imports corrects dans tous les fichiers
- [x] Pas de warnings sérieux

### Validations Données
- [x] 19 questions définies dans Cloud Function
- [x] Pas de doublons d'IDs questions
- [x] Structure Firestore cohérente
- [x] Champs requis présents

### Validations Architecture
- [x] Matching algorithm testé avec cas connus
- [x] TabBar UI testée avec tous types de questions
- [x] Validation des réponses implementée
- [x] Cache mechanism en place

---

## 🔧 Étape 1: Déployer Cloud Function

### 1.1 Préparation
```bash
cd /Users/macos/Desktop/IRIS\ SECURE/cheers/mobile-app/functions
npm install  # Assurer dépendances à jour
```

### 1.2 Test Local
```bash
firebase emulators:start --only functions
# Dans une autre terminal:
curl -X POST http://localhost:5001/$(gcloud config get-value project)/us-central1/migratePreferencesQuestions \
  -H "Content-Type: application/json" \
  -d '{"test": true}'

# Vérifier les logs:
# "Migration completed successfully!"
# Stats: { inactiveCount: X, newQuestionsCount: 19, validatedCount: 19, sections: 7 }
```

### 1.3 Déployer en Production
```bash
firebase deploy --only functions:migratePreferencesQuestions

# Expected output:
# ✔  functions[migratePreferencesQuestions]: Successful created function

firebase functions:log  # Vérifier logs
```

### 1.4 Vérifier le déploiement
```bash
# Via Firebase Console:
# Cloud Functions → Détails fonction
# - Status: Active ✓
# - Runtime: Node.js 20
# - Trigger: onCall
# - Memory: 256MB
```

---

## 📊 Étape 2: Exécuter la Migration Firestore

### 2.1 Trigger de Migration
```bash
# Option 1: Via Firebase Console (UI)
# 1. Cloud Functions → migratePreferencesQuestions
# 2. Cliquer "TESTING" onglet
# 3. Cliquer "EXECUTE"
# 4. Attendre succès

# Option 2: Via gcloud CLI
gcloud functions call migratePreferencesQuestions \
  --region=us-central1 \
  --gen2

# Option 3: Via curl (si authent=public)
curl -X POST \
  https://us-central1-PROJECT_ID.cloudfunctions.net/migratePreferencesQuestions \
  -H "Content-Type: application/json" \
  -d '{"test": false}'
```

### 2.2 Vérifier Résultat
```
Response: {
  "success": true,
  "message": "Migration completed successfully!",
  "stats": {
    "inactiveCount": <old_count>,  // Nombre de vieilles questions
    "newQuestionsCount": 19,
    "validatedCount": 19,
    "sections": 7
  }
}
```

### 2.3 Vérifier dans Firestore
```
Firebase Console → Firestore Database → Collections

1. PreferencesQuestions collection
   ✓ 19 documents total
   ✓ IDs: q_1_1, q_1_2, q_1_3, q_1_4, ... q_7_19
   ✓ Tous active=true
   ✓ Tous avec champs: id, question, section, type, answers, answerKeys

2. Vérifier document exemple: q_1_1
   {
     "active": true,
     "answers": {...},
     "answerKeys": [...],
     "id": "q_1_1",
     "question": "What do you want a relationship to be...",
     "question Order": 1,
     "section": 1,
     "sectionOrder": 1,
     "sectionTitle": "WHAT YOU WANT IN LOVE",
     "type": "single",
     "createdAt": <timestamp>
   }

3. Compter documents par section:
   - Section 1: 4 questions
   - Section 2: 2 questions
   - Section 3: 3 questions
   - Section 4: 3 questions (with Q11 type=ranking)
   - Section 5: 3 questions (with Q13 type=multi)
   - Section 6: 3 questions
   - Section 7: 1 question (type=rating)
   Total: 19 ✓
```

### 2.4 Backup (Recommandé)
```bash
# Exporter les données avant migration
gcloud firestore export gs://YOUR_BUCKET/backup_$(date +%Y%m%d_%H%M%S)

# Ou via console Firebase:
# Firestore → Paramètres → Gérer les sauvegardes
```

---

## 📱 Étape 3: Déployer App Flutter

### 3.1 Préparation Code
```bash
cd /Users/macos/Desktop/IRIS\ SECURE/cheers/mobile-app
flutter clean
flutter pub get
```

### 3.2 Analyse & Vérification
```bash
flutter analyze
# ✓ No issues found!

flutter test test/preferences_questions_test.dart
# Expected: Tous les tests passent (✓ X tests)
```

### 3.3 Build
```bash
# Android
flutter build apk --release  # Output: build/app/outputs/apk/release/app-release.apk
# flutter build appbundle --release  # Pour Google Play Store

# iOS
flutter build ios --release  # Puis build via Xcode si nécessaire
```

### 3.4 Deploy à Users
```bash
# Option 1: Distribuer APK directement (TEST)
# - Envoyer fichier APK à testeurs
# - Tester sur devices réels

# Option 2: Beta via Play Store
# - Upload appbundle à Google Play Console
# - Créer beta track
# - Inviter testeurs

# Option 3: Production
# - Augmenter version dans pubspec.yaml
# - Créer tag git: v1.x.x
# - Upload en production
```

---

## ✅ Étape 4: Validation Post-Déploiement

### 4.1 Tests Manuels (Checklist QA)

**Test 1: Nouvel Utilisateur - Profil Complet**
- [ ] Ouvrir app (nouveau device ou clear data)
- [ ] Aller à profil → CompletProfileScreen apparaît
- [ ] Voir 7 onglets (What You Want, How You Handle, etc.)
- [ ] Cliquer Tab 1, voir questions 1-4
- [ ] Cliquer Tab 2, voir questions 5-6
- [ ] Répondre à Q1 (single select) → voir réponse stockée
- [ ] Aller à Q11 (ranking), drag-drop items → vérifier ordre changé
- [ ] Aller à Q13 (multi select), choisir 3+ activités → tous selectable
- [ ] Aller à Q19 (rating), noter chaque trait 1-5 → tous slots remplissables
- [ ] Clicker Save → modal succès → profil sauvegardé

**Test 2: Vérifier Firestore**
- [ ] Aller à Firebase Console
- [ ] Voir document User avec `user_preferences`:
  ```json
  {
    "q_1_1": "a",
    "q_5_13": ["workout", "reading"],
    "q_4_11": { "words": 1, "touch": 2, ... },
    "q_7_19_emotional_intelligence": 5,
    ...
  }
  ```

**Test 3: Utilisateur Existant - Force Re-answer**
- [ ] Device avec anciennes préférences
- [ ] Logout → Login
- [ ] Modal apparaît: "Update your preferences"
- [ ] Forcer à CompleteProfileScreen
- [ ] Vérifier anciennes réponses ne pré-remplissent pas

**Test 4: Matching**
- [ ] 2 devices, user A et user B
- [ ] User A: répondre identiquement à User B
- [ ] Aller à Suggestions → voir User B
- [ ] Vérifier score = 95%+ 
- [ ] Cliquer breakdown → voir sections (all 80%+)
- [ ] User A: changer réponses complètement opposées
- [ ] Suggestionscreen re-load → score devrait baisser

**Test 5: UI/UX**
- [ ] SingleSelect: radio buttons affichent correctement
- [ ] Multi: checkboxes wrap correctement
- [ ] Ranking: drag-drop fonctionne, position visuelle change
- [ ] Rating: 1-5 buttons, sélection claire
- [ ] Progress: scrolling smooth, pas lag
- [ ] Save: disable jusqu'à toutes réponses

### 4.2 Tests Automatisés
```bash
flutter test test/preferences_questions_test.dart

# Expected output:
# ✓ PreferencesQuestion
#   ✓ fromDocument creates question with all fields
#   ✓ copyWith creates modified copy
#   ✓ toMap converts to serializable format
#   ✓ Ranking question detected correctly
#   ✓ Multi question detected correctly
#   ✓ Rating question detected correctly
#
# ✓ UserPreferencesAnswers
#   ✓ addSingleAnswer stores answer
#   ... [5 more]
#
# ✓ PreferencesQuestion Integration
#   ✓ Question with all types can be created
#   ✓ Answers can be created and converted
#
# All tests passed! (15 tests)
```

### 4.3 Performance Check
```bash
# Vérifier pas de lag au switching tabs
# Vérifier pas de memory leaks
# Checker Firebase calls timing (< 2sec load)
```

---

## 🔍 Étape 5: Monitoring Post-Déploiement

### 5.1 Firestore Monitoring
```bash
# Firebase Console → Firestore → Monitoring
# - Watch: Read/Write operations
- Expected: Small spike during user preference saves
# - Alert if: >1000 reads/writes per second (anomalies)
```

### 5.2 Crashlytics
```bash
# Firebase Console → Crashlytics
# - Monitor crashes in CompleteProfileScreen
# - Monitor crashes in matching algorithm
# - Alert threshold: 0 new issues immediately
```

### 5.3 Analytics
```bash
# Track events:
# - preferences_questions_viewed
# - preferences_answered
# - preferences_saved
# Expected: Usage metrics normal
```

### 5.4 Logs
```bash
firebase functions:log --limit 50

# Check for:
# - Migration success logs
# - No validation error logs
# - Performance is acceptable
```

---

## ⚠️ Rollback Plan

### Si erreurs après déploiement:

**Scenario 1: Cloud Function Error**
```bash
# Rollback function
firebase deploy --only functions:migratePreferencesQuestions_old  # If backup exists
# Ou delete function et re-deploy old version
```

**Scenario 2: App Crashes**
```bash
# Publish previous app version to Play Store
# Notify users
# Investigate issue in parallel
```

**Scenario 3: Data Corruption**
```bash
# Restore Firestore from backup
gcloud firestore restore \
  --backup-location=gs://YOUR_BUCKET/backup_YYYYMMDD_HHMMSS \
  --async
```

**Scenario 4: Matching Algorithm Issues**
```bash
# Update SuggestionsService._calculateQuizCompatibility()
# Redeploy app with fix
# Rematch existing suggestions
```

---

## 📞 Contacts & Support

**Cloud Function Issues**: Firebase Support  
**App Crashes**: Mobile Team  
**Firestore Issues**: Firebase Database Support  
**QA Questions**: QA Lead

---

## 🎉 Success Criteria

✅ **Déploiement réussi si**:
- Cloud Function exécutée sans erreurs
- 19 questions présentes dans Firestore
- App compilée et déployée
- Tous les tests QA passent
- Utilisateurs peuvent répondre à toutes les questions
- Matching calcule correctement
- Pas de crashes rapportés 24h après déploiement

---

## 📝 Notes

- **Breaking Change**: Utilisateurs doivent ré-répondre aux 19 nouvelles questions
- **Timing**: Mieux déployer pendant heures creuses (ex: 2-4 AM)
- **Communication**: Notifier les utilisateurs de la mise à jour des profils requis
- **Timeline**: Cloud Function (5 min) + App Deploy (15 min) + Monitoring (10 min) = ~30 min total

---

**Status**: READY FOR DEPLOYMENT ✅  
**Last Reviewed**: 18 mai 2026  
**Next Review**: Post-deployment (24h check-in)
