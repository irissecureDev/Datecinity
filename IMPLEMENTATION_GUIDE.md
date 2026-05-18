# 📋 PreferencesQuestions Refactor - Implémentation Complète

**Date**: 18 mai 2026  
**Statut**: ✅ Code implémenté et compilé  
**Prochaines étapes**: Déploiement et tests

---

## 📊 Résumé Exécutif

Refactorisation complète du système de PreferencesQuestions avec :
- ✅ 19 nouvelles questions organisées en 7 sections
- ✅ Cloud Function de migration Firestore
- ✅ Modèles de données enrichis (section, type, ranking support)
- ✅ API pour gestion des questions et réponses
- ✅ **Matching algorithm réel** pondéré par section (20%, 15%, 20%, 15%, 15%, 10%, 5%)
- ✅ Refactorisation UI complète (TabBar, 4 types de questions)
- ✅ Widget breakdown pour afficher détails du matching

---

## 🔧 Fichiers Modifiés / Créés

### Phase 1: Cloud Function (Node.js)
- **File**: `functions/index.js`
- **Changes**: Ajout de `exports.migratePreferencesQuestions`
- **Features**:
  - Marque toutes les anciennes questions comme inactives
  - Ajoute les 19 nouvelles questions avec structure complète
  - Validation automatique (no duplicates, required fields)
  - Chunking pour éviter les limites Firestore

### Phase 2: Modèles Dart
- **New File**: `lib/datas/preferences_answer.dart`
  - `PreferencesAnswer`: Classe pour réponses individuelles
  - `UserPreferencesAnswers`: Manager pour stocker et convertir réponses
  
- **Updated**: `lib/datas/preferences_question.dart`
  - Ajout: `section`, `sectionTitle`, `sectionOrder`, `type`
  - Ajout: `answerKeys` pour ordre d'affichage
  - Ajout: Helpers (`isMultiSelect`, `isRanking`, `isRating`, `isSingleSelect`)
  - Ajout: `copyWith()`, `toMap()` pour sérialisation

### Phase 3a: APIs
- **Updated**: `lib/api/preferences_questions_api.dart`
  - Ajout: `getAllQuestions()` - récupère toutes les questions actives
  - Ajout: `getQuestionsBySection(int)` - filtre par section
  - Ajout: `getAllQuestionsGrouped()` - Map<section, List<questions>>
  - Ajout: `getSectionMetadata()` - info sur sections
  - Ajout: Cache avec TTL (60 minutes)

- **New File**: `lib/api/preferences_answers_api.dart`
  - `validateAnswers()` - valide format et complétude
  - `updateUserAnswers()` - sauvegarde à Firestore avec validation
  - `getUserAnswers()` - récupère réponses existantes
  - `clearUserAnswers()` - reset (optionnel)

### Phase 3b: Algorithme de Matching
- **Updated**: `lib/services/suggestions_service.dart`
  - Remplacé `_calculateQuizCompatibility()` avec implémentation réelle
  - Ajout: `_calculateSectionCompatibility(section)` - score par section
  - Ajout: Comparateurs spécialisés :
    - `_compareSingleSelectAnswers()` (0 ou 1.0)
    - `_compareMultiSelectAnswers()` (Jaccard similarity)
    - `_compareRankingAnswers()` (Spearman-like correlation)
    - `_compareRatingAnswers()` (inverse diff absolutte)
  - **Pondération par section**:
    - Section 1: 20% (Love Goals)
    - Section 2: 15% (Feelings)
    - Section 3: 20% (Communication)
    - Section 4: 15% (Intimacy)
    - Section 5: 15% (Lifestyle)
    - Section 6: 10% (Personality)
    - Section 7: 5% (Values)

### Phase 4: UI Refactor
- **Completely Rewritten**: `lib/screens/complete_profile_screen.dart`
  - **Architecture**: TabBar (7 sections) au lieu de PageView (19 pages)
  - **Question Types Support**:
    - `single`: RadioListTile (default)
    - `multi`: Wrap de checkboxes
    - `ranking`: ReorderableListView avec drag-drop
    - `rating`: SegmentedButton 1-5 (Q19 only)
  - **Features**:
    - Validation complète avant sauvegarde
    - Pré-remplissage des réponses existantes
    - Progression visuelle par section
    - Bouton Save unique en bas (bottom navigation)
    - Design moderne Material 3

- **New Widget**: `lib/widgets/matching_breakdown_widget.dart`
  - Affiche score global + breakdown par section
  - Code couleur basé sur score (green 80+, amber 40+, red <40)
  - Expandable/collapsible
  - Affiche weight de chaque section (×20%, ×15%, etc.)

---

## 🗄️ Structure Firestore (Nouvelle)

### Collection: `PreferencesQuestions`

```json
{
  "id": "q_1_1",
  "question": "What do you want a relationship to be in your life?",
  "section": 1,
  "sectionTitle": "WHAT YOU WANT IN LOVE",
  "sectionOrder": 1,
  "questionOrder": 1,
  "type": "single",
  "answers": {
    "a": "A place that supports me while I grow",
    "b": "A team where we build a life together",
    "c": "A close and deep emotional bond",
    "d": "Something natural that grows without pressure"
  },
  "answerKeys": ["a", "b", "c", "d"],
  "active": true,
  "createdAt": "2026-05-18T10:00:00Z"
}
```

### Questions par Section (19 total)
- **Section 1** (Q1-4): What You Want In Love
- **Section 2** (Q5-6): How You Handle Feelings
- **Section 3** (Q7-9): How You Communicate
- **Section 4** (Q10-12): Love & Connection
  - Q11 est `type: "ranking"` (5 love languages)
- **Section 5** (Q13-15): Lifestyle & Habits
  - Q13 est `type: "multi"` (activities)
- **Section 6** (Q16-18): Personality & Connection Style
- **Section 7** (Q19): What Matters Most
  - Q19 est `type: "rating"` (8 traits, 1-5 scale)

---

## 📝 Format de Stockage des Réponses Utilisateur

Les réponses sont stockées dans `Users/{userId}/user_preferences` :

```json
{
  "q_1_1": "a",                                    // Single select
  "q_5_13": ["workout", "reading", "music"],      // Multi select (array)
  "q_4_11": {                                      // Ranking (map)
    "words": 1,
    "touch": 2,
    "time": 3,
    "service": 4,
    "gifts": 5
  },
  "q_7_19_emotional_intelligence": 5,             // Rating (flat keys)
  "q_7_19_political_alignment": 3,
  ...
}
```

---

## 🚀 Déploiement - Checklist

### Étape 1: Cloud Function (Firestore)
```bash
cd functions/
npm install  # Si besoin
firebase emulators:start --only functions  # Test local
npm run deploy  # Deploy to production
```

### Étape 2: Exécuter la Migration
```bash
# Via Firebase Console:
# Cloud Functions → migratePreferencesQuestions → TEST → EXECUTE
# Ou via curl (si fonction est publique):
# curl -X POST https://region-project.cloudfunctions.net/migratePreferencesQuestions
```

### Étape 3: Vérifier Firestore
```
Firebase Console → Firestore → PreferencesQuestions collection
- Vérifier: 19 documents
- Vérifier: Tous active=true
- Vérifier: Pas de doublons (ids uniques)
- Vérifier: Orders sont séquentiels
```

### Étape 4: Déployer App Flutter
```bash
flutter clean
flutter pub get
flutter analyze  # Vérifier pas d'erreurs
flutter build apk  # ou ios
# Deployer en production
```

### Étape 5: Testing Manual
**Scenarios à tester**:

1. **Nouvel utilisateur**:
   - Voir l'écran CompleteProfileScreen
   - Vérifier les 7 onglets
   - Répondre à toutes les questions
   - Vérifier chaque type: single, multi, ranking, rating
   - Sauvegarder → vérifier Firestore `user_preferences`

2. **Utilisateur existant avec anciennes réponses**:
   - Anciennes réponses doivent être ignorées (breaking change OK)
   - Modal "Update preferences" doit apparaître au login
   - Forcer à ré-répondre aux 19 nouvelles questions

3. **Matching**:
   - 2 utilisateurs avec réponses identiques → score ~95-100%
   - 2 utilisateurs opposés → score ~0-20%
   - Afficher breakdown par section dans SuggestionScreen

---

## ⚠️ Breaking Changes

1. **Anciennes questions supprimées**: `active=false`
2. **Anciennes réponses ignorées**: Format incompatible avec nouvelle structure
3. **Utilisateurs doivent ré-répondre** aux 19 nouvelles questions au 1er login après migration
4. **IDs des questions changent**: `q_1_1`, `q_1_2`, ... (ancien format absent)

---

## 📚 Notes Techniques

### Matching Algorithm (Détails)

Pour chaque paire d'utilisateurs:

1. Pour chaque section (1-7):
   - Pour chaque question dans la section:
     - Récupérer réponses de user1 et user2
     - Comparer selon type:
       - **Single**: exact match = 1.0, else 0.3
       - **Multi**: Jaccard similarity + bonus
       - **Ranking**: correlation coefficient (simplified)
       - **Rating**: 1 - (avgDiff / 4)
     - Moyenne des scores questions → score section
   - Appliquer weight section × score section
2. Somme pondérée de tous sections = score final (0-100%)

### Cache
- Questions cached 60 minutes en mémoire
- Après migration: `PreferencesQuestionsApi().refreshCache()`
- Si modifications questions après déploiement: appeler `clearCache()` sur app

### Validation
- Avant sauvegarde: vérifier toutes 19 questions ont réponse
- Vérifier format (single=string, multi=list, etc.)
- PreferencesAnswersApi gère la validation

---

## 🔗 Références aux Fichiers Critiques

| Fichier | Rôle |
|---------|------|
| [lib/screens/complete_profile_screen.dart](lib/screens/complete_profile_screen.dart) | UI TabBar (7 sections) |
| [lib/api/preferences_questions_api.dart](lib/api/preferences_questions_api.dart) | Fetch questions |
| [lib/api/preferences_answers_api.dart](lib/api/preferences_answers_api.dart) | Validation + Save |
| [lib/services/suggestions_service.dart](lib/services/suggestions_service.dart) | Matching algorithm |
| [lib/datas/preferences_question.dart](lib/datas/preferences_question.dart) | Model question |
| [lib/datas/preferences_answer.dart](lib/datas/preferences_answer.dart) | Manager réponses |
| [lib/widgets/matching_breakdown_widget.dart](lib/widgets/matching_breakdown_widget.dart) | Breakdown display |
| [functions/index.js](functions/index.js) | Cloud Function migration |

---

## 🐛 Troubleshooting

### Issue: "No questions available"
**Solution**: Vérifier que Cloud Function `migratePreferencesQuestions` a été exécutée et que les documents sont dans Firestore.

### Issue: "Validationechoued: Missing answers"
**Solution**: L'utilisateur doit répondre à TOUTES les 19 questions avant de pouvoir sauvegarder.

### Issue: Old answers appearing
**Solution**: Cela ne devrait pas arriver. Si c'est le cas, vérifier le format de `user_preferences`. Les anciennes clés (sans "q_" prefix) doivent être migrées manuellement ou ignorées.

### Issue: Matching score always 0.5
**Solution**: Vérifier que les deux utilisateurs ont répondu à au moins quelques questions. Le score minimum est 0.5 pour éviter matching aléatoire.

---

## 📈 Prochaines Améliorations (Future)

1. **Analytics**: Tracker les réponses les plus populaires par question
2. **A/B Testing**: Tester différentes pondérations par section
3. **Machine Learning**: Prédire matching basé sur patterns utilisateur
4. **Offline Mode**: Cacher questions localement
5. **Progressive Completion**: Permettre aux utilisateurs de répondre au fur et à mesure (pas tout d'un coup)
6. **Rematch**: Bouton pour ré-répondre aux questions et recalculer matching

---

**Version**: 1.0  
**Last Updated**: 18 mai 2026  
**Maintainer**: Mobile App Team
