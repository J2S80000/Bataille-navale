# 🚀 Guide de Configuration Firebase pour Bataille Navale

## 1️⃣ Créer un Projet Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com)
2. Cliquez sur **"Créer un projet"**
3. Nommez-le: `bataille-navale` (ou votre choix)
4. Acceptez les conditions et créez

## 2️⃣ Ajouter une Application Mobile

### Pour Android:
1. Cliquez sur l'icône **Android** dans Firebase Console
2. Entrez votre nom de package (ex: `com.example.bataille_navale`)
3. Suivez les étapes, téléchargez `google-services.json`
4. Placez le fichier à: `android/app/google-services.json`

### Pour iOS:
1. Cliquez sur l'icône **iOS** dans Firebase Console
2. Entrez votre Bundle ID
3. Téléchargez `GoogleService-Info.plist`
4. Ouvrez `ios/Runner.xcworkspace` et ajoutez le fichier au projet

## 3️⃣ Activer l'Authentification

1. Dans Firebase Console → **Authentication**
2. Cliquez sur **"Commencer"** → **Sign-in method**
3. Activez:
   - ✅ **Email/Password**
   - ✅ **Google** (optionnel)

## 4️⃣ Configurer Firestore Database

1. Dans Firebase Console → **Firestore Database**
2. Cliquez **"Créer une base de données"**
3. Mode: **Mode production** (pour sécurité)
4. Région: Choisissez la plus proche (ex: `europe-west1`)

### Ajouter les règles de sécurité:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Authentification requise
    match /players/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null; // Voir les autres joueurs
    }

    match /games/{gameId} {
      allow read: if request.auth != null && 
        (resource.data.player1.id == request.auth.uid || 
         resource.data.player2.id == request.auth.uid);
      allow write: if request.auth != null &&
        (request.resource.data.player1.id == request.auth.uid || 
         request.resource.data.player2.id == request.auth.uid);
      
      match /moves/{moveId} {
        allow read, write: if request.auth != null;
      }
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## 5️⃣ Installer les Dépendances

```bash
cd bataille_navale
flutter pub get
```

## 6️⃣ (Optionnel) Configurer Firebase CLI

```bash
npm install -g firebase-tools
firebase login
firebase init firestore
```

## 📊 Structure Firestore

```
bataille-navale-project/
├── players/
│   └── {userId}/
│       ├── (player data)
│       └── game_stats/
│           └── {gameId}: GameStatistics
│
├── games/
│   └── {gameId}/
│       ├── (game data)
│       └── moves/
│           └── {moveId}: Move
```

## ✅ Vérifier la Configuration

1. Lancez l'app: `flutter run`
2. Vérifiez que Firebase s'initialise sans erreur
3. Testez l'authentification

## 🐛 Résolution de Problèmes

### "FirebaseCore not initialized"
- Assurez-vous que `Firebase.initializeApp()` est appelé dans `main()`
- Vérifiez les fichiers de configuration Firebase

### Erreurs de compilation Android
- Vérifiez que `google-services.json` est au bon endroit
- Mettez à jour les versions dans `pubspec.yaml`

### Erreurs iOS
- Ouvrez le workspace: `open ios/Runner.xcworkspace`
- Vérifiez que `GoogleService-Info.plist` est ajouté au target

---

**Besoin d'aide?** Consultez la [documentation Firebase officielle](https://firebase.google.com/docs/flutter)
