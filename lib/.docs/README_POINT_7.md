# Point 7 - Service en Arrière-plan 🌐

## Vue d'ensemble

Le **Service en Arrière-plan** est un système intelligent qui maintient les suggestions de profils à jour en continu, même lorsque l'application n'est pas active au premier plan.

## Fonctionnalités principales

### 🎯 Surveillance géolocalisation
- **Tracking continu** : Surveille la position de l'utilisateur en arrière-plan
- **Changements significatifs** : Déclenche des mises à jour seulement si l'utilisateur se déplace de plus de 100m
- **Optimisation batterie** : Utilise `LocationAccuracy.medium` pour équilibrer précision et consommation

### 🔄 Mises à jour automatiques
- **Intervalle adaptatif** :
  - Foreground : toutes les 5 minutes
  - Background : toutes les 15 minutes
- **Détection intelligente** : Identifie les nouveaux profils par rapport au cache
- **Cooldown système** : Évite les mises à jour trop fréquentes (minimum 1 minute)

### 🔔 Notifications push intelligentes
- **Profils à proximité** : Alerte quand des utilisateurs compatibles sont à moins de 10m
- **Cooldown utilisateur** : Maximum 1 notification par utilisateur par heure
- **Integration service** : Utilise `SuggestionsNotificationsService.checkAndNotifyNearbyMatches()`

### 🔋 Optimisation ressources
- **États app** : Adapte automatiquement selon foreground/background
- **Gestion mémoire** : Cache intelligent avec nettoyage automatique
- **Permissions** : Gestion robuste des permissions géolocalisation

## Architecture technique

### Services principaux

```dart
BackgroundSuggestionsService
├── Surveillance géolocalisation
├── Gestion cache suggestions  
├── Notifications automatiques
└── Optimisation batterie

BackgroundServiceConfig
├── Initialisation auto
├── Gestion préférences
└── Configuration utilisateur

BackgroundServiceControlWidget
├── Interface contrôle
├── Statistiques temps réel
└── Actions manuelles
```

### États et transitions

```
[App Start] → [Check Preferences] → [Auto Init?]
                                         ↓
[Running] ←→ [Stopped] ←→ [Background Mode]
    ↓           ↓              ↓
[Update]    [Manual]      [Reduced Freq]
```

## Utilisation

### 1. Initialisation automatique
```dart
// Au démarrage de l'app
await BackgroundServiceConfig.initializeOnStartup();
```

### 2. Contrôle manuel
```dart
// Démarrer
final success = await BackgroundSuggestionsService.initialize();

// Arrêter  
await BackgroundSuggestionsService.stop();

// Forcer mise à jour
await BackgroundSuggestionsService.forceUpdate();
```

### 3. Interface utilisateur
```dart
// Widget de contrôle
BackgroundServiceControlWidget()

// Bouton flottant
BackgroundServiceFloatingButton()

// Écran configuration
BackgroundServiceScreen()
```

## Fichiers créés

### Services core
- `lib/services/background_suggestions_service.dart` - Service principal (470+ lignes)
- `lib/services/background_service_config.dart` - Configuration et préférences

### Interfaces utilisateur
- `lib/widgets/background_service_control_widget.dart` - Widget de contrôle
- `lib/widgets/background_service_floating_button.dart` - Bouton flottant animé
- `lib/screens/background_service_screen.dart` - Écran configuration
- `lib/screens/background_service_test_screen.dart` - Interface de test

## Permissions requises

### iOS (Info.plist)
```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Pour découvrir des profils compatibles à proximité</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Pour suggérer des profils basés sur votre position</string>
```

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

## Configuration optimale

### Paramètres recommandés
- **Distance significative** : 100 mètres
- **Intervalle foreground** : 5 minutes
- **Intervalle background** : 15 minutes
- **Cooldown notifications** : 1 heure par utilisateur
- **Seuil distance proximité** : 10 mètres

### Stratégies batterie
- Mode adaptatif selon état app
- Précision géolocalisation équilibrée
- Cache intelligent des suggestions
- Cooldowns pour éviter les spam

## Tests et validation

### Interface de test
L'écran `BackgroundServiceTestScreen` permet de :
- Tester l'initialisation
- Contrôler démarrage/arrêt
- Forcer des mises à jour
- Simuler les changements d'état
- Visualiser les logs en temps réel
- Analyser les statistiques détaillées

### Métriques surveillées
- État du service (actif/inactif)
- Mode courant (foreground/background)
- Nombre de suggestions en cache
- Cooldowns actifs
- Position GPS actuelle
- Dernière mise à jour

## Intégration Point 6

Le service s'intègre parfaitement avec l'interface à onglets :
- Mise à jour automatique des suggestions dans l'onglet Discover
- Synchronisation avec les groupes de proximité (5m, 10m, 25m, 50m+)
- Notifications push qui dirigent vers l'onglet approprié

## Évolutions futures

### Phase 2 possibles
- **Zones géofencées** : Notifications en entrant/sortant de lieux spécifiques
- **Apprentissage** : IA pour optimiser les intervalles selon les habitudes
- **Mode économie** : Paramètres ultra-économes pour batterie faible
- **Analytics** : Métriques détaillées d'utilisation et performance

## Statut Point 7

✅ **COMPLÉTÉ** - Service en arrière-plan entièrement implémenté avec :
- Surveillance géolocalisation continue
- Mises à jour automatiques intelligentes  
- Notifications push optimisées
- Interface de contrôle complète
- Gestion batterie avancée
- Tests et validation intégrés

**Prêt pour Point 8** : Intelligence artificielle et apprentissage automatique 🤖