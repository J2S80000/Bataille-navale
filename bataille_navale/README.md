# ⚓ Bataille Navale - App Mobile avec Firebase et IA

Une application mobile Flutter pour jouer à la Bataille Navale avec support complet pour:
- 🎮 Jeu en temps réel
- 🔥 Backend Firebase (Firestore + Auth)
- 📊 Analytics avancées et collecte d'historique
- 🤖 IA évolutive basée sur algorithme génétique
- 📈 Statistiques détaillées et heatmaps

---

## 🎯 Fonctionnalités

### Gameplay
- ✅ Placement de navires (manuel ou aléatoire)
- ✅ Combat au tour par tour
- ✅ Détection de coups (touché, manqué, coulé)
- ✅ Mode 1v1 ou vs IA
- ✅ Historique complet des coups

### Analytics
- ✅ Précision par partie (accuracy %)
- ✅ Heatmap 10x10 des positions attaquées
- ✅ Détection de patterns de jeu (linéaire, diagonal, etc.)
- ✅ Coefficient de prédictibilité
- ✅ Stats agrégées (win rate, total coups, etc.)

### IA (Algorithme Génétique)
- ✅ Entraînement sur l'historique de parties
- ✅ 5 poids adaptables
- ✅ Prédiction de coups basée sur heuristiques

### Backend
- ✅ Authentification Firebase (Email/Password)
- ✅ Firestore pour persistence
- ✅ Sauvegarde de toutes les parties

---

## 🚀 Démarrage Rapide

```bash
cd bataille_navale
flutter pub get
flutter run
```

**Configuration Firebase requise** → Voir `FIREBASE_SETUP.md`

---

## 📁 Structure

```
lib/
├── models/              # Modèles de données (Board, Game, Move, Stats)
├── services/            # Firebase, GameService, Analytics
├── ai/                  # Algorithme génétique + Predictor
├── screens/             # UI Flutter
└── main.dart            # Entry point

test/
└── bataille_navale_test.dart    # Tests unitaires
```

---

## 📚 Documentation Complète

- **[FIREBASE_SETUP.md](FIREBASE_SETUP.md)** - Comment configurer Firebase
- **[TECHNICAL_GUIDE.md](TECHNICAL_GUIDE.md)** - Architecture et système d'IA

---

## 🤖 IA avec Algorithme Génétique

L'IA s'entraîne sur l'historique des parties et apprend à prédir les coups:

1. **Population**: 20 stratégies avec 5 poids chacune
2. **Évolution**: 50 générations avec sélection, crossover, mutation
3. **Heuristiques**: Proximité hits, densité navires, espacement, hotspots, exploration

```dart
// Entraîner l'IA
final ga = GeneticAlgorithm(populationSize: 20, generations: 50);
ga.train(historiqueDeParies);
final bestStrategy = ga.getBestStrategy();

// Prédire un coup
final predictor = MovePredictor(strategy: bestStrategy, trainingData: stats);
final (row, col) = predictor.predictNextMove(board, gameHistory);
```

---

## 📊 Données Collectées

Par partie: position des coups, résultats, timing, précision, patterns d'attaque, heatmap, etc.

---

## ✅ Tests

```bash
flutter test
```

Couverts: validation placement, traitement coups, stats, génétique, sérialisation

---

## 🔒 Sécurité

- Authentification requise pour tout
- Chaque joueur ne peut modifier que ses données
- Règles Firestore strictes (voir FIREBASE_SETUP.md)

---

**Dernière mise à jour**: Novembre 2024
