## 🎯 Configuration Web MongoDB + Android Firebase - DONE

Votre application Flutter **Bataille Navale** est maintenant configurée pour:

### 📱 **Web** (Chrome/Firefox)
- Utilise **MongoDB local** via Docker
- Port: `27018` (interne: `27017`)
- Persistence des statistiques de jeu en local
- Interface optionnelle: http://localhost:8081

### 🔥 **Android**
- Utilise **Firebase** (prêt pour intégration)
- Cloud Firestore pour les données
- Firebase Auth pour les utilisateurs
- Synchronisation cloud

---

## 🚀 Démarrage rapide

### 1️⃣ Démarrer MongoDB (une seule fois)
```bash
cd "C:\Users\jessy\Desktop\Pro\Devoir\S5\Analyse\BatailleNavale\bataille_navale"
docker-compose up -d
```

### 2️⃣ Lancer l'app Web
```bash
flutter run -d chrome
```

### 3️⃣ Vérifier MongoDB (optionnel)
Ouvrir: http://localhost:8081
- Utilisateur: `admin`
- Mot de passe: `password`

---

## 📊 Architecture du code

**Sélection automatique de la base de données:**
```dart
FirebaseService()
  ↓
kIsWeb == true?
  ├─ OUI  → MongoDBService → http://localhost:27018
  └─ NON  → FirebaseService → Cloud Firestore (Android)
```

**Fichiers modifiés:**
- ✅ `lib/services/firebase_service.dart` - Détection plateforme
- ✅ `lib/services/mongodb_service.dart` - Nouveau service MongoDB
- ✅ `pubspec.yaml` - Ajout mongo_dart + http
- ✅ `docker-compose.yml` - Configuration MongoDB
- ✅ `scripts/init-mongo.js` - Initialisation collections

---

## 🛑 Arrêter MongoDB
```bash
docker-compose down
```

### ⚠️ Réinitialiser complètement (supprime les données)
```bash
docker-compose down -v
```

---

## 🐛 Troubleshooting

| Problème | Solution |
|----------|----------|
| Port 27018 déjà utilisé | `docker-compose down` puis relancer |
| MongoDB refuse la connexion | Vérifier: `docker-compose ps` |
| Blank white screen en web | Vérifier console: F12 → Console |
| Données non sauvegardées | MongoDB doit être actif (`docker-compose up -d`) |

---

## ✨ Fonctionnalités

### Disponible sur Web maintenant:
- ✅ Créer/jouer des parties locales
- ✅ Sauvegarder les statistiques dans MongoDB
- ✅ Consulter l'historique des jeux
- ✅ Interface de gestion: Mongo Express

### Prêt pour Android:
- 🔥 Firebase Cloud Firestore (données cloud)
- 🔑 Firebase Authentication (comptes utilisateurs)
- 📱 Synchronisation cross-device

---

## 📚 Documentation complète

Voir: `WEB_MONGODB_ANDROID_FIREBASE_SETUP.md`

---

## 💡 Développement

**Pendant le développement web:**
```bash
# Terminal 1: MongoDB
docker-compose up

# Terminal 2: Flutter
flutter run -d chrome

# Utiliser "r" pour hot reload
```

**Debugger:**
- VS Code: Debug > Start Debugging
- Chrome DevTools: F12 dans le navigateur

---

**L'app est prête à être testée! Lancer `docker-compose up -d` puis `flutter run -d chrome`**
