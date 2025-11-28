# 🎯 Guide d'intégration finale: Web MongoDB + Android Firebase

## ✅ État actuel du projet

### Conteneurs Docker
```
✅ bataille_navale_mongodb      → Actif (Port 27018)
✅ bataille_navale_mongo_express → Actif (Port 8081)
```

### Code Flutter
```
✅ firebase_service.dart   → Détecte kIsWeb automatiquement
✅ mongodb_service.dart    → Connecte à MongoDB local
✅ pubspec.yaml            → Dépendances installées
✅ models/statistics.dart  → Sérialisation JSON compatible MongoDB
```

---

## 🎮 Pour tester l'app Web

### Étape 1: Vérifier que MongoDB est actif
```bash
docker-compose ps
# Doit montrer 2 conteneurs "Up"
```

### Étape 2: Lancer l'app Flutter
```bash
flutter run -d chrome
```

### Étape 3: Jouer à une partie
1. Ouvrir l'app dans Chrome
2. Créer une nouvelle partie
3. Placer les navires
4. Jouer contre l'ordinateur
5. Terminer la partie

### Étape 4: Vérifier les données dans MongoDB
```bash
# Ouvrir http://localhost:8081
# Sélectionner "bataille_navale" → "game_statistics"
# Vous devriez voir les statistiques sauvegardées
```

---

## 🔥 Pour préparer Android + Firebase

### Prérequis
- Android Studio
- Compte Firebase
- Fichier `google-services.json`

### Procédure
1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Créer un nouveau projet ou sélectionner "bataille_navale"
3. Ajouter une application Android
4. Télécharger `google-services.json`
5. Placer dans `android/app/`
6. Lancer: `flutter run -d android`

Le code `FirebaseService` détectera automatiquement qu'il ne s'agit pas du web et utilisera Firebase.

---

## 📊 Fonctionnalités par plateforme

### 🌐 Web (MongoDB)
| Fonctionnalité | Statut |
|---|---|
| Créer parties | ✅ |
| Sauvegarder stats | ✅ (MongoDB) |
| Charger historique | ✅ (MongoDB) |
| Multi-joueur cloud | ❌ |
| Comptes utilisateurs | ⚠️ (Local only) |

### 📱 Android (Firebase)
| Fonctionnalité | Statut |
|---|---|
| Créer parties | ✅ |
| Sauvegarder stats | ✅ (Firestore) |
| Charger historique | ✅ (Firestore) |
| Multi-joueur cloud | ✅ (avec Firebase) |
| Comptes utilisateurs | ✅ (Firebase Auth) |

---

## 🔄 Sélection automatique backend

```dart
/// FirebaseService détecte automatiquement:

// Sur le navigateur web
if (kIsWeb) {
  // Utilise MongoDB
  await _mongoDb.initialize();
}

// Sur Android/iOS
else {
  // Utilisera Firebase
  // (À configurer avec google-services.json)
}
```

**Aucun code à modifier entre web et mobile!** ✨

---

## 🚀 Commandes utiles

### Développement web
```bash
# Lancer MongoDB
docker-compose up -d

# Lancer l'app
flutter run -d chrome

# Voir les logs MongoDB
docker-compose logs -f mongodb

# Arrêter tout
docker-compose down
```

### Développement Android
```bash
# Lancer l'émulateur
emulator @Pixel_4_API_30

# Lancer l'app
flutter run -d emulator-5554

# Ou depuis Android Studio (Shift+F10)
```

### Production
```bash
# Build web
flutter build web

# Build Android
flutter build apk
flutter build appbundle

# Build web pour serveur
# → Contenu dans build/web/
```

---

## 📁 Fichiers créés

```
├── lib/
│   └── services/
│       ├── firebase_service.dart      ✅ Mise à jour
│       ├── mongodb_service.dart       ✨ NOUVEAU
│       └── index.dart                 ✅ Mise à jour
├── docker-compose.yml                 ✨ NOUVEAU
├── scripts/
│   └── init-mongo.js                  ✨ NOUVEAU
├── pubspec.yaml                       ✅ Mise à jour
├── QUICK_START_WEB_MONGODB.md         ✨ NOUVEAU
├── WEB_MONGODB_ANDROID_FIREBASE_SETUP.md  ✨ NOUVEAU
└── ARCHITECTURE_WEB_MONGODB_ANDROID_FIREBASE.md  ✨ NOUVEAU
```

---

## 🧪 Scénarios de test

### Scénario 1: Web local
```
1. Démarrer MongoDB
2. Lancer app Chrome
3. Créer partie
4. Terminer partie
5. Vérifier stats dans Mongo Express
✅ Stats doivent être persistées dans MongoDB
```

### Scénario 2: Android avec Firebase (futur)
```
1. Configurer Firebase
2. Placer google-services.json
3. Lancer app sur device/émulateur
4. Créer partie
5. Terminer partie
6. Vérifier stats dans Firebase Console
✅ Stats doivent être persistées dans Firestore
```

### Scénario 3: Offline web
```
1. Démarrer MongoDB
2. Lancer app Chrome
3. Arrêter MongoDB (docker-compose down)
4. Créer partie en local
5. Relancer MongoDB
6. Rafraîchir la page
✅ App continue de fonctionner, stats locales persistes
```

---

## ⚙️ Configuration par défaut

### MongoDB
- URL: `http://localhost:27018`
- Base: `bataille_navale`
- User: `admin`
- Pass: `password`
- Collections auto-créées: ✅

### Firebase (À configurer)
- Project ID: À définir
- Firestore Region: À définir
- Auth Methods: À configurer

---

## 🆘 Troubleshooting

| Problème | Cause | Solution |
|---------|-------|----------|
| "Cannot connect to MongoDB" | MongoDB pas actif | `docker-compose up -d` |
| "Port 27018 already in use" | Autre service | `docker-compose down` puis recommencer |
| Blank white screen web | Erreur Javascript | F12 → Console pour les erreurs |
| Données non sauvegardées | MongoDB déconnecté | Vérifier `docker-compose logs` |
| `kIsWeb is not defined` | Import manquant | `import 'package:flutter/foundation.dart';` |

---

## 📞 Support

### Pour le web (MongoDB):
- Vérifier les logs: `docker-compose logs mongodb`
- Accéder à Mongo Express: http://localhost:8081
- Console Flutter: `flutter run -d chrome --verbose`

### Pour Android (Firebase):
- Firebase Console: https://console.firebase.google.com
- Google Services file: Vérifier `android/app/google-services.json`
- Android Studio: Build → Make Project

---

## ✨ Résumé

✅ **Web**: MongoDB local (27018) = développement rapide sans cloud
✅ **Android**: Firebase (Firestore) = production-ready avec cloud sync
✅ **Code**: Un seul `FirebaseService` pour les deux! 🎉

**L'app est maintenant configurable pour web ET mobile!**

---

## 🚀 Prochaines étapes

1. ✅ Tester le web avec MongoDB
2. ⏭️ Configurer Firebase pour Android
3. ⏭️ Ajouter l'authentification utilisateur
4. ⏭️ Implémenter le multiplayer en réseau
5. ⏭️ Déployer en production

**Démarrer:** `docker-compose up -d && flutter run -d chrome`
