# Configuration Multi-Backend: MongoDB (Web) + Firebase (Android)

## ✅ Configuration complétée

### 1. **Dépendances ajoutées** (`pubspec.yaml`)
```yaml
mongo_dart: ^0.10.5   # Client MongoDB pour le web
http: ^1.1.0          # HTTP client pour les requêtes REST
```

### 2. **Nouveau service MongoDB** (`lib/services/mongodb_service.dart`)
- ✅ Client HTTP pour MongoDB local
- ✅ Sauvegarde des statistiques de jeu
- ✅ Récupération de l'historique des jeux
- ✅ Gestion des erreurs de connexion gracieuse
- ✅ Timeout de 5 secondes sur les requêtes

**Port configuré**: `27018` (accessible via `http://localhost:27018`)

### 3. **Service Firebase mis à jour** (`lib/services/firebase_service.dart`)
- ✅ Détection de la plateforme (`kIsWeb`)
- ✅ Utilise MongoDB sur le web
- ✅ Utiliserait Firebase sur Android/iOS
- ✅ Intégration transparente avec `GameStatistics`

### 4. **Infrastructure Docker** (`docker-compose.yml`)
```bash
Services:
- MongoDB: Port 27018 (docker 27017 interne)
- Mongo Express: Port 8081 (interface web optionnelle)
```

### 5. **Scripts de configuration** (`scripts/init-mongo.js`)
- ✅ Collections créées: `game_statistics`, `games`, `players`
- ✅ Index créés pour optimiser les requêtes

## 🚀 Architecture finale

```
┌─────────────────────────────────────────────────┐
│          Flutter Bataille Navale                 │
├─────────────────────────────────────────────────┤
│  kIsWeb ?                                        │
│  ├─ OUI (Web)  → FirebaseService → MongoDB     │
│  │              (localhost:27018)                │
│  └─ NON (Mobile) → FirebaseService → Firebase  │
│                   (Cloud Firestore)             │
└─────────────────────────────────────────────────┘
```

## 📖 Utilisation

### Démarrer MongoDB (Docker)
```bash
docker-compose up -d
```

### Vérifier la connexion
```bash
# MongoDB Express (interface web)
http://localhost:8081

# Ou tester directement dans l'app
flutter run -d chrome
```

### Arrêter MongoDB
```bash
docker-compose down
```

## 📊 Flux de données

### Web (Chrome/Firefox)
```
App Game → FirebaseService.saveGameStatistics()
         → kIsWeb check (true)
         → MongoDBService.saveGameStatistics()
         → HTTP POST http://localhost:27018/bataille_navale/game_statistics
         → MongoDB stocke les stats
```

### Android (futur)
```
App Game → FirebaseService.saveGameStatistics()
         → kIsWeb check (false)
         → Utilise Firebase Cloud Firestore
         → Cloud Firestore stocke et synchronise
```

## 🛠️ Tests

Les statistiques seront maintenant persistées dans MongoDB:
- Créer une partie en local
- Terminer la partie
- Vérifier que les stats apparaissent dans Mongo Express (http://localhost:8081)
- Les stats surviveront aux rechargements de page

## 📝 Notes importantes

1. **Port 27018 vs 27017**: Port 27018 utilisé car 27017 était déjà occupé
2. **Pas d'authentification requise**: Docker-compose utilise admin:password par défaut
3. **Données persistantes**: Sauvegardées dans `mongodb_data` volume Docker
4. **Web uniquement**: MongoDB n'est utilisé que si `kIsWeb == true`
5. **Fallback gracieux**: Si MongoDB n'est pas disponible, l'app continue de fonctionner

## 🔗 URLs utiles

- **App Web**: http://localhost:yourport (où yourport = port Flutter)
- **Mongo Express**: http://localhost:8081
- **MongoDB**: mongodb://localhost:27018

## ✨ Prochaines étapes

Pour Android/Firebase:
1. Configurer Google Services JSON
2. Implémenter l'authentification Firebase
3. Configurer Firestore rules
4. Tester sur Android Studio

Pour production:
1. Héberger MongoDB Atlas ou serveur dédié
2. Configurer SSL/TLS
3. Implémenter l'authentification MongoDB
4. Mettre en place les backups
