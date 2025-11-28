# Configuration Firebase pour Bataille Navale

## 🔧 Instructions Étape par Étape

### 1. Créer un Projet Firebase

1. Allez sur https://console.firebase.google.com
2. Cliquez sur **"Créer un projet"**
3. Remplissez les informations:
   - Nom: `bataille-navale` (ou votre choix)
   - Localisation: Sélectionnez votre pays
   - Acceptez les conditions
4. Cliquez **"Créer un projet"**
5. Attendez 1-2 minutes

### 2. Ajouter une Application Flutter

#### Pour Android:

1. Dans la console Firebase, cliquez l'icône **Android** (ou "+ Ajouter une application")
2. Remplissez:
   - **Nom du package Android**: `com.example.bataille_navale`
   - **Surnom de l'app**: Bataille Navale
3. Cliquez **"Enregistrer l'application"**
4. Téléchargez **`google-services.json`**
5. Placez le fichier à: 
   ```
   android/app/google-services.json
   ```
6. Cliquez **"Suivant"** et suivez les instructions (modifiez `build.gradle` si nécessaire)

#### Pour iOS:

1. Dans la console Firebase, cliquez l'icône **iOS**
2. Remplissez:
   - **Bundle ID iOS**: `com.example.battailleNavale` (sans underscores)
   - **Surnom de l'app**: Bataille Navale
3. Cliquez **"Enregistrer l'application"**
4. Téléchargez **`GoogleService-Info.plist`**
5. Ouvrez `ios/Runner.xcworkspace` dans Xcode
6. Drag-and-drop le fichier `GoogleService-Info.plist` dans le projet
7. Cochez **"Copy items if needed"** et **Runner** target
8. Cliquez **"Finish"**

### 3. Activer l'Authentification

1. Dans la console Firebase → **Authentication** (menu gauche)
2. Cliquez **"Commencer"**
3. Onglet **"Sign-in method"**
4. Activez:
   - ✅ **Email/Password** (obligatoire)
   - ✅ **Google** (optionnel)

### 4. Créer la Base de Données Firestore

1. Dans la console Firebase → **Firestore Database**
2. Cliquez **"Créer une base de données"**
3. Configuration:
   - Mode: **Production**
   - Localisation: Choisissez la plus proche (ex: `europe-west1`)
4. Cliquez **"Créer"**

### 5. Ajouter les Règles de Sécurité

1. Dans Firestore → Onglet **Règles**
2. Remplacez le contenu par:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Authentification requise globalement
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    // Collection des joueurs
    match /players/{userId} {
      // Chacun peut lire/modifier son propre profil
      allow read, write: if isAuthenticated() && isOwner(userId);
      
      // Tous les joueurs authentifiés peuvent lire les autres profils
      allow list: if isAuthenticated();
      
      // Sous-collection: statistiques des parties
      match /game_stats/{gameId} {
        allow read: if isAuthenticated() && isOwner(userId);
        allow write: if isAuthenticated() && isOwner(userId);
      }
      
      // Sous-collection: stats agrégées
      match /aggregate/{document=**} {
        allow read: if isAuthenticated() && isOwner(userId);
        allow write: if isAuthenticated() && isOwner(userId);
      }
    }

    // Collection des parties
    match /games/{gameId} {
      // Lire/modifier si on est l'un des deux joueurs
      allow read: if isAuthenticated() && 
        (resource.data.player1.id == request.auth.uid || 
         resource.data.player2.id == request.auth.uid);
      
      allow write: if isAuthenticated() && 
        (request.resource.data.player1.id == request.auth.uid || 
         request.resource.data.player2.id == request.auth.uid);
      
      // Sous-collection: coups de la partie
      match /moves/{moveId} {
        allow read, write: if isAuthenticated();
      }
    }

    // Tout le reste: interdit
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

3. Cliquez **"Publier"**

### 6. Vérifier la Configuration

1. Lancez l'app:
   ```bash
   flutter run
   ```

2. Vérifiez que Firebase s'initialise sans erreur
3. Testez l'inscription/connexion

### 7. (Optionnel) CLI Firebase

Pour gérer Firebase en ligne de commande:

```bash
# Installer Firebase CLI
npm install -g firebase-tools

# Se connecter
firebase login

# Initialiser dans votre projet
cd bataille_navale
firebase init

# Déployer les règles (à refaire quand vous les modifiez)
firebase deploy --only firestore:rules
```

---

## 📦 Dépendances à Installer

```bash
flutter pub get
```

Les dépendances requises:
- `firebase_core: ^3.8.0`
- `cloud_firestore: ^5.4.0`
- `firebase_auth: ^5.3.0`
- `provider: ^6.1.5+1`
- `uuid: ^4.0.0`
- `equatable: ^2.0.5`
- `fl_chart: ^0.68.0`

---

## 🔑 Obtenir les Clés Firebase

Si vous avez besoin de la configuration complète:

1. Dans Console Firebase → **Project Settings** (roue ⚙️ en haut)
2. Onglet **Service Accounts**
3. **Generate New Private Key** pour le backend (optionnel)
4. Onglet **General** pour voir les clés d'API

---

## 🚀 Lancer l'Application

```bash
# Installer les dépendances
flutter pub get

# Lancer sur un device
flutter run

# Ou spécifier le device
flutter run -d chrome        # Pour web
flutter run -d emulator-5554  # Pour émulateur
```

---

## ✅ Checklist de Configuration

- [ ] Créé le projet Firebase
- [ ] Ajouté l'app Android (google-services.json)
- [ ] Ajouté l'app iOS (GoogleService-Info.plist)
- [ ] Activé Authentication (Email/Password)
- [ ] Créé Firestore Database
- [ ] Configuré les règles de sécurité
- [ ] Exécuté `flutter pub get`
- [ ] Lancé `flutter run` avec succès

---

## 🐛 Résolution de Problèmes

### "FirebaseCore not initialized"
- Vérifiez que `Firebase.initializeApp()` est dans `main()`
- Vérifiez que les fichiers de configuration sont au bon endroit

### Erreur Android: "google-services.json not found"
- Assurez-vous que le fichier est à `android/app/google-services.json`
- Mettez à jour gradle si nécessaire

### Erreur iOS: "GoogleService-Info.plist not found"
- Ouvrez `ios/Runner.xcworkspace` (pas `.xcodeproj`)
- Vérifiez que le fichier est dans le target Runner
- Build Settings: Vérifiez Bundle ID

### Erreur Firestore: "Permission denied"
- Vérifiez les règles de sécurité
- Vérifiez que vous êtes authentifié
- Consultez les logs Firebase Console

### "dependency on cloud_firestore" error
- Mettez à jour les dépendances:
  ```bash
  flutter pub upgrade
  ```

---

## 📞 Besoin d'aide?

- Documentation Firebase: https://firebase.google.com/docs/flutter
- Console Firebase: https://console.firebase.google.com
- Stack Overflow: Tag `firebase` + `flutter`

---

**Dernière mise à jour**: Novembre 2024
