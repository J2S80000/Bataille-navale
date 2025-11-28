# 🚀 Getting Started - Bataille Navale

## ⚡ 5 Minutes Quick Start

### 1. Installer les dépendances
```bash
cd bataille_navale
flutter pub get
```

### 2. Configurer Firebase (IMPORTANT!)
- Suivez exactement: `FIREBASE_SETUP.md` (5-10 minutes)
- Téléchargez `google-services.json` (Android)
- Téléchargez `GoogleService-Info.plist` (iOS)

### 3. Lancer l'app
```bash
flutter run
```

### 4. Exécuter les tests
```bash
flutter test
```

**Vous devriez voir**: ✅ Tous les tests passent

---

## 📚 Documentation par Besoin

### "Je veux comprendre l'architecture"
→ Lire: `TECHNICAL_GUIDE.md` (15 min)

### "Je veux configurer Firebase"
→ Lire: `FIREBASE_SETUP.md` (10 min)
→ Action: Suivre le guide étape par étape

### "Je veux développer les écrans UI"
→ Lire: `QUICK_REFERENCE.md` (5 min)
→ Modifier: `lib/screens/`
→ Ajouter: Widgets Flutter

### "Je veux utiliser l'IA"
→ Exemple: `lib/examples.dart` - section "Train & Predict"
→ Code: `lib/ai/genetic_algorithm.dart`

### "Je veux ajouter de nouvelles données"
→ Modifier: `lib/models/`
→ Mettre à jour: `lib/services/firebase_service.dart`
→ Tester: `test/bataille_navale_test.dart`

### "Je veux déboguer"
→ Consulter: `QUICK_REFERENCE.md` - "Common Patterns"
→ Vérifier: Tests dans `test/`

---

## 🎯 Workflow de Développement

### Pour développer une nouvelle feature:

1. **Créer le modèle** (si nécessaire)
   ```dart
   // lib/models/my_model.dart
   class MyModel {
     // Ajouter champs
     MyModel copyWith({...}) { ... }
     Map<String, dynamic> toJson() { ... }
     factory MyModel.fromJson(Map) { ... }
   }
   ```

2. **Ajouter au service** (Firebase ou Game)
   ```dart
   // lib/services/firebase_service.dart
   Future<void> saveMyModel(MyModel model) async {
     await _firestore.collection('my_models')
       .doc(model.id).set(model.toJson());
   }
   ```

3. **Tester**
   ```dart
   // test/bataille_navale_test.dart
   test('MyModel serialization', () {
     final model = MyModel(...);
     final json = model.toJson();
     final restored = MyModel.fromJson(json);
     expect(restored, model);
   });
   
   flutter test
   ```

4. **Utiliser dans l'UI**
   ```dart
   // lib/screens/my_screen.dart
   final firebase = context.read<FirebaseService>();
   await firebase.saveMyModel(model);
   ```

---

## 🐛 Dépannage Rapide

### "FirebaseCore not initialized"
```dart
// Dans main(), AVANT runApp():
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp();
```

### "google-services.json not found"
```
Vérifier: android/app/google-services.json existe?
Action: Télécharger depuis Firebase Console
```

### "Tests échouent"
```bash
flutter clean
flutter pub get
flutter test
```

### "Erreur de dépendance"
```bash
flutter pub upgrade
flutter pub get
```

### "App crash au lancement"
```
1. Vérifier les logs: flutter run
2. Vérifier Firebase Config
3. Vérifier les imports
4. Commenter les tests qui échouent
```

---

## 📂 Structure Rapide

```
lib/
├── main.dart              → Entrypoint (NE PAS MODIFIER)
├── bataille_navale.dart   → Exports
├── models/                → Structures de données
│   ├── game.dart
│   ├── board.dart
│   ├── move.dart
│   └── ...
├── services/              → Logique métier
│   ├── firebase_service.dart
│   ├── game_service.dart
│   └── analytics_service.dart
├── ai/                    → Algorithme génétique
│   ├── genetic_algorithm.dart
│   └── predictor.dart
├── screens/               → 🚨 À DÉVELOPPER
│   ├── main_screen.dart   → Accueil
│   ├── game_screen.dart   → À créer
│   ├── stats_screen.dart  → À créer
│   └── ...
└── examples.dart          → Exemples d'utilisation
```

---

## ✅ Checklist pour Démarrer

- [ ] `flutter pub get` réussi
- [ ] Firebase configuré (IMPORTANT!)
- [ ] `flutter run` lance l'app
- [ ] `flutter test` passe tous les tests
- [ ] Lire `README.md` pour vue d'ensemble
- [ ] Lire `QUICK_REFERENCE.md` pour API
- [ ] Comprendre structure `lib/models/`
- [ ] Comprendre services dans `lib/services/`
- [ ] Consulter `lib/examples.dart` pour patterns

---

## 🎮 Exemple Complet Minimal

```dart
import 'package:bataille_navale/services/game_service.dart';
import 'package:bataille_navale/models/index.dart';

void main() {
  // 1. Créer joueurs
  final alice = Player(
    id: 'alice',
    name: 'Alice',
    email: 'alice@test.com',
    createdAt: DateTime.now(),
  );
  
  final bob = Player(
    id: 'bob',
    name: 'Bob',
    email: 'bob@test.com',
    createdAt: DateTime.now(),
  );

  // 2. Créer partie
  final gameService = GameService();
  var game = gameService.createGame(alice, bob);
  
  // 3. Générer plateaux
  game = game.copyWith(
    board1: gameService.generateRandomShipPlacement(),
    board2: gameService.generateRandomShipPlacement(),
    status: GameStatus.playing,
  );
  
  print('✅ Partie créée: ${game.id}');
  print('👥 ${game.player1.name} vs ${game.player2.name}');
  
  // 4. Jouer un coup
  final (result, updatedGame) = gameService.processMove(game, 5, 5);
  game = updatedGame;
  
  print('🎯 Coup résultat: ${result.toString()}');
  print('📊 Total coups: ${game.moves.length}');
}
```

**Lancer**: `dart lib/examples.dart` (en tant qu'exécutable Dart)

---

## 📱 Tester sur Device Réel

### Android
```bash
flutter run -d device_id
```

### iOS
```bash
open ios/Runner.xcworkspace
# Dans Xcode: Product → Run (ou Cmd+R)
```

### Web (optionnel)
```bash
flutter run -d chrome
```

---

## 🔗 Fichiers Importants

| Fichier | Rôle | Modifier? |
|---------|------|-----------|
| `lib/main.dart` | Entrypoint | ❌ Non |
| `lib/models/` | Structures de données | ✅ Oui |
| `lib/services/` | Logique métier | ✅ Oui |
| `lib/ai/` | Algorithme génétique | ✅ Avec précaution |
| `lib/screens/` | UI Screens | ✅ À développer |
| `test/` | Tests | ✅ À étendre |
| `TECHNICAL_GUIDE.md` | Documentation | 📖 Lire |

---

## 🎯 Prochaines Actions

### Maintenant (5 minutes)
1. `flutter pub get`
2. Configurer Firebase
3. `flutter run`

### Phase 2 (2-3 semaines)
1. Développer `lib/screens/game_screen.dart`
2. Afficher le plateau 10x10
3. Implémenter les interactions

### Phase 3 (2 semaines)
1. Ajouter multiplayer
2. Intégrer notifications
3. Real-time updates

---

## 💡 Tips & Tricks

### Hot Reload (pendant développement)
```bash
# Lancer avec hot reload activé
flutter run

# Dans le terminal, appuyer 'r' pour reload
# Appuyer 'R' pour redémarrage complet
```

### Debugger
```bash
# Utiliser DevTools
flutter pub global activate devtools
devtools
```

### Performance
```bash
# Profiler l'app
flutter run --profile

# Trace de perf
flutter run --release
```

---

## 📞 Getting Help

1. **Erreur de compilation**: Vérifier `SETUP_GUIDE.md`
2. **Question API**: Vérifier `QUICK_REFERENCE.md`
3. **Architecture**: Lire `TECHNICAL_GUIDE.md`
4. **Exemples**: Consulter `lib/examples.dart`
5. **Tests**: Voir `test/bataille_navale_test.dart`

---

## 🎉 Vous êtes Prêt!

- ✅ Backend complet
- ✅ AI entraînable
- ✅ Firebase configuré
- ✅ Tests passants
- ✅ Documentation complète

**Prochaine étape**: Développer les écrans UI (Phase 2)

Bonne chance! 🚀

---

**Dernière mise à jour**: Novembre 2024
**Pour questions**: Consultez la documentation appropriée
