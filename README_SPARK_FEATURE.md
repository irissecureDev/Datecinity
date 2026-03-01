# Configuration Firebase pour la fonctionnalité Spark

## Actions à effectuer côté Firebase

### 1. Créer la collection Sparks dans Firestore

Allez dans Firebase Console > Firestore Database et créez la collection `Sparks`.

**Structure d'un document Spark :**
```json
{
  "spark_id": "user1_user2_timestamp",
  "user1_id": "string",
  "user2_id": "string", 
  "detected_at": "Timestamp",
  "expires_at": "Timestamp",
  "distance": "number (km)",
  "compatibility": "number (0.0 - 1.0)",
  "compatibility_details": {
    "values_alignment": {
      "score": 0.75,
      "title": "Values Alignment",
      "icon_type": "star"
    },
    "communication_style": {
      "score": 0.8,
      "title": "Communication Style", 
      "icon_type": "chat",
      "common_interests": ["hiking", "music"]
    },
    "pace_energy": {
      "score": 0.7,
      "title": "Pace & Energy",
      "icon_type": "energy"
    },
    "spark_reasons": [
      "You both enjoy hiking and music",
      "Shared spiritual values"
    ]
  },
  "status": "pending|revealed|liked|matched|expired|declined",
  "user1_status": "pending|revealed|liked|declined",
  "user2_status": "pending|revealed|liked|declined"
}
```

### 2. Configurer les règles de sécurité Firestore

Ajoutez ces règles dans Firebase Console > Firestore Database > Rules :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ... règles existantes ...

    // Règles pour la collection Sparks
    match /Sparks/{sparkId} {
      // Lecture : seuls les utilisateurs impliqués peuvent lire
      allow read: if request.auth != null && 
        (resource.data.user1_id == request.auth.uid || 
         resource.data.user2_id == request.auth.uid);
      
      // Création : utilisateur authentifié uniquement
      allow create: if request.auth != null && 
        request.resource.data.user1_id == request.auth.uid;
      
      // Mise à jour : seuls les utilisateurs impliqués peuvent modifier
      allow update: if request.auth != null && 
        (resource.data.user1_id == request.auth.uid || 
         resource.data.user2_id == request.auth.uid);
      
      // Suppression : non autorisée (utiliser le statut expired)
      allow delete: if false;
    }
  }
}
```

### 3. Créer des index Firestore

Allez dans Firebase Console > Firestore Database > Indexes et créez ces index composites :

**Index 1 - Sparks par user1_id et expiration :**
- Collection: `Sparks`
- Champs:
  - `user1_id` (Ascending)
  - `expires_at` (Ascending)

**Index 2 - Sparks par user2_id et expiration :**
- Collection: `Sparks`
- Champs:
  - `user2_id` (Ascending)
  - `expires_at` (Ascending)

**Index 3 - Sparks par statut et expiration (pour le nettoyage) :**
- Collection: `Sparks`
- Champs:
  - `status` (Ascending)
  - `expires_at` (Ascending)

### 4. Cloud Function pour le nettoyage automatique des Sparks expirés (Optionnel)

Ajoutez cette fonction dans `functions/index.js` pour nettoyer automatiquement les sparks expirés :

```javascript
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
```

### 5. Déployer les Cloud Functions

```bash
cd functions
npm install
firebase deploy --only functions
```

### 6. Types de notifications

L'application utilise ces types de notifications pour les Sparks :
- `spark` : Nouveau spark détecté (quelqu'un compatible est à proximité)
- `spark_like` : L'autre personne a aimé votre profil
- `spark_match` : Les deux ont aimé = Match !

Ces types sont déjà gérés par la Cloud Function `sendPushNotification` existante.

## Flow de la fonctionnalité Spark

1. **Détection de proximité** : L'app détecte un utilisateur compatible à moins de 500m
2. **Création du Spark** : Un document Spark est créé dans Firestore
3. **Notification Push** : L'autre utilisateur reçoit une notification "A Spark is forming!"
4. **Compte à rebours** : 10 minutes pour agir
5. **Révélation** : L'utilisateur clique pour voir le profil
6. **Compatibilité** : Affichage des raisons de compatibilité
7. **Like** : Si l'utilisateur aime, notification envoyée à l'autre
8. **Match** : Si les deux aiment → ils peuvent s'écrire

## Test de la fonctionnalité

Pour tester localement :
1. Créez deux comptes utilisateurs
2. Placez-les géographiquement proches (utilisez l'émulateur de localisation)
3. Assurez-vous que les profils sont compatibles (hobbies, religion, etc.)
4. La détection se fait automatiquement lors des mises à jour de position
