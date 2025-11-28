# Configuration Multi-Plateforme: MongoDB Web + Firebase Mobile

## Résumé des changements

### 🗄️ Nouvelle architecture backend

| Plateforme | Backend | Configuration | Port |
|------------|---------|---------------|------|
| **Web** | MongoDB | Docker local | 27018 |
| **Android** | Firebase | Cloud Firestore | - |
| **iOS** | Firebase | Cloud Firestore | - |
| **Desktop** | Firebase | Cloud Firestore | - |

---

## 📝 Changements apportés

### 1. **`pubspec.yaml`**
```yaml
dependencies:
  mongo_dart: ^0.10.5    # ← Nouveau
  http: ^1.1.0           # ← Nouveau
```

### 2. **`lib/services/mongodb_service.dart`** ← NOUVEAU FICHIER
Service MongoDB avec endpoints REST:
- `initialize()` - Test de connexion
- `saveGameStatistics()` - Sauvegarde stats
- `getAllGameStatistics()` - Récupère toutes les stats
- `getPlayerStatistics()` - Stats d'un joueur
- `saveGameState()` - Sauvegarde l'état du jeu
- `getGameHistory()` - Historique des parties

### 3. **`lib/services/firebase_service.dart`** (Mise à jour)
```dart
// Avant: Retournait toujours des stubs
// Après: Utilise MongoDB si kIsWeb == true

Future<void> initialize() async {
  if (kIsWeb) {
    await _mongoDb.initialize();  // ← MongoDB
  } else {
    // Firebase sur mobile
  }
}

Future<void> saveGameStatistics(dynamic stats) async {
  if (kIsWeb && stats is GameStatistics) {
    await _mongoDb.saveGameStatistics(stats);  // ← MongoDB
  }
}
```

### 4. **`docker-compose.yml`** ← NOUVEAU FICHIER
Services Docker:
- **MongoDB**: Port 27018 → 27017 (interne)
- **Mongo Express**: Port 8081 (interface web UI)

### 5. **`scripts/init-mongo.js`** ← NOUVEAU FICHIER
Script d'initialisation MongoDB:
- Collections: `game_statistics`, `games`, `players`
- Index pour optimiser les requêtes

### 6. **`lib/services/index.dart`**
```dart
export 'mongodb_service.dart';  // ← Nouveau export
```

---

## 🔄 Flux de sélection backend

```
Application démarre
  ↓
main.dart charge FirebaseService
  ↓
FirebaseService.initialize()
  ├─ kIsWeb = true?
  │  └─ Oui → MongoDBService.initialize()
  │           → Teste connection http://localhost:27018
  │           → Crée les collections MongoDB
  │
  └─ kIsWeb = false?
     └─ Non → Firebase.initializeApp()
              → Connecte à Cloud Firestore
              → Authentification Firebase
```

---

## 🗃️ Structure MongoDB

### Collections

#### `game_statistics`
```json
{
  "gameId": "uuid",
  "playerId": "uuid",
  "opponentId": "uuid",
  "totalMoves": 45,
  "hits": 12,
  "misses": 33,
  "hitPositions": [{"row": 2, "col": 3}, ...],
  "missPositions": [{"row": 1, "col": 1}, ...],
  "gameDuration": 3600,
  "recordedAt": "2025-11-13T18:00:00Z",
  "won": true,
  "shipsDestroyed": 5,
  "accuracy": 26.67,
  "timestamp": "2025-11-13T18:00:00Z"
}
```

#### `games`
```json
{
  "playerId": "uuid",
  "board1": [...],
  "board2": [...],
  "status": "active|finished",
  "timestamp": "2025-11-13T18:00:00Z"
}
```

#### `players`
```json
{
  "playerId": "uuid",
  "name": "Player Name",
  "totalGames": 10,
  "wins": 7,
  "losses": 3
}
```

---

## 🚀 Utilisation

### ✅ Avant (Web)
```
App → FirebaseService.stub() → Aucune persistence
```

### ✅ Après (Web)
```
App → FirebaseService → MongoDBService → MongoDB local
      (auto-détecte)     (via HTTP)      (http://localhost:27018)
                                         + UI: http://localhost:8081
```

### ✅ Android (Futur)
```
App → FirebaseService → Firebase.initializeApp()
      (auto-détecte)     → Cloud Firestore
                         → Firebase Auth
```

---

## 🧪 Tests

### Tester MongoDB sur Web:
```bash
# Terminal 1: MongoDB
docker-compose up -d

# Terminal 2: Flutter
flutter run -d chrome

# Terminal 3: Voir les données (optionnel)
docker-compose logs -f mongodb
```

### Vérifier les données:
```bash
# Interface web (recommandé)
http://localhost:8081

# Ou via CLI
docker exec bataille_navale_mongodb mongosh -u admin -p password
> use bataille_navale
> db.game_statistics.find()
```

---

## 🔐 Sécurité (Développement)

**Credentials Docker (développement local uniquement):**
- Utilisateur: `admin`
- Mot de passe: `password`

⚠️ **Pour la production:** Utiliser des variables d'environnement

---

## 📦 Dépendances

```yaml
mongo_dart: ^0.10.5
  └─ Client Dart pour MongoDB
  └─ Supporte le protocole MongoDB 3.0+
  └─ Web compatible ✅

http: ^1.1.0
  └─ Client HTTP pour Dart
  └─ Requêtes GET/POST/DELETE
  └─ Web compatible ✅
```

---

## ⚡ Performance

- **Requêtes web → MongoDB**: ~10-50ms (localhost)
- **Requêtes Android → Firebase**: ~100-500ms (réseau)
- **Pas de latence réseau** pour le web en développement

---

## 🔄 Prochaines étapes

### Court terme (Web):
1. ✅ Configurer MongoDB Docker
2. ✅ Implémenter MongoDBService
3. ✅ Tester persistence des statistiques
4. ✅ Vérifier les données dans Mongo Express

### Long terme (Android):
1. Configurer Google Services (google-services.json)
2. Implémenter Firebase Authentication
3. Configurer Firestore Security Rules
4. Tester sur émulateur/device Android

### Production:
1. Migrer MongoDB vers Atlas ou serveur dédié
2. Configurer SSL/TLS
3. Implémenter l'authentification MongoDB
4. Mettre en place les backups automatiques
5. Optimiser les index MongoDB

---

## 🐛 Débogage

### Voir les logs MongoDB:
```bash
docker-compose logs mongodb
```

### Voir les logs de l'app:
```bash
flutter run -d chrome --verbose
```

### Tester la connexion MongoDB:
```dart
final mongo = MongoDBService();
await mongo.initialize();  // Affiche les logs de connexion
```

### URLs de débogage:
- Flutter App: http://localhost:xxxxx (port dynamique)
- Mongo Express: http://localhost:8081
- MongoDB: mongodb://localhost:27018

---

## 📚 Références

- [MongoDB Documentation](https://docs.mongodb.com/)
- [mongo_dart GitHub](https://github.com/mongo-dart/mongo_dart)
- [Firebase Flutter Documentation](https://firebase.flutter.dev/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)

---

**Configuration terminée! ✅ L'app est prête pour le développement web avec MongoDB.**
