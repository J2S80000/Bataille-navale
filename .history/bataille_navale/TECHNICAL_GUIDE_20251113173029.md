# 📚 Architecture Technique - Bataille Navale

## Vue d'Ensemble

Système complet de Bataille Navale avec:
- **Backend Firebase**: Authentification + Firestore
- **Historique de coups**: Enregistrement détaillé de toutes les parties
- **Analytics avancées**: Stats, patterns, heatmaps
- **IA évolutive**: Algorithme génétique pour apprendre des patterns

---

## 📦 Modèles de Données

### 1. `Player`
```dart
- id: String (UID Firebase)
- name: String
- email: String
- wins: int
- losses: int
- gamesPlayed: int
- createdAt: DateTime
```

### 2. `Game`
```dart
- id: String (UUID)
- player1: Player
- player2: Player
- board1, board2: Board
- moves: List<Move> (historique)
- currentTurnPlayerId: String
- winnerId: String?
- status: GameStatus (setup, playing, finished, abandoned)
- createdAt, finishedAt: DateTime
- player1IsAI, player2IsAI: bool
```

### 3. `Move`
```dart
- id: String (UUID)
- row, col: int (0-9)
- result: MoveResult (miss, hit, sunk)
- timestamp: DateTime
- playerId: String (qui a joué ce coup)
```

### 4. `Board`
```dart
- grid: List<List<Cell>> (10x10)
- ships: List<Ship> (5 navires)
- isVisible: bool (affiche les navires?)
```

### 5. `Ship`
```dart
- id: String
- type: ShipType (carrier, battleship, cruiser, submarine, destroyer)
- cells: List<(int, int)> (positions)
- isVertical: bool
- hits: int (coups reçus)
```

### 6. `GameStatistics`
```dart
- gameId: String
- playerId: String
- totalMoves: int
- hits: int
- misses: int
- hitPositions: List<(int, int)>
- missPositions: List<(int, int)>
- accuracy: double (0-100)
- won: bool
- shipsDestroyed: int
- gameDuration: Duration
```

### 7. `PlayerStatisticsAggregate` (Stats agrégées)
```dart
- playerId: String
- totalGames: int
- totalWins: int
- winRate: double (0-1)
- averageAccuracy: double (0-100)
- heatmap: List<int> (100 cellules)
- moveTiming: Map<String, int> (patterns temporels)
```

---

## 🎮 Services

### `FirebaseService`
Gère toute la communication Firebase:
- Authentification (sign up, sign in, sign out)
- CRUD sur les joueurs
- CRUD sur les parties
- Sauvegarde des stats
- Leaderboards

**Exemple**:
```dart
final firebase = FirebaseService();
await firebase.initialize();
final user = await firebase.signIn(email, password);
final game = await firebase.getGame(gameId);
```

### `GameService`
Logique pure du jeu (pas de Firebase):
- Placement des navires
- Validation des coups
- Calcul des stats
- Génération de plateaux aléatoires

**Exemple**:
```dart
final service = GameService();
final board = service.generateRandomShipPlacement();
final (result, updatedGame) = service.processMove(game, row, col);
```

### `AnalyticsService`
Analyse des données et patterns:
- Construit les stats agrégées
- Génère les heatmaps
- Détecte les patterns de jeu
- Calcule les scores de prédictibilité

**Exemple**:
```dart
final analytics = AnalyticsService();
final stats = await analytics.buildPlayerStatistics(playerId, gameStats);
final hotspots = analytics.getHotspots(stats.heatmap);
```

---

## 🤖 Système d'IA avec Algorithme Génétique

### Architecture

```
GeneticAlgorithm (entraîneur)
    ↓
    ├─→ AIStrategy (population de stratégies)
    │    └─→ weights: [w0, w1, w2, w3, w4]
    │
    └─→ MovePredictor (évaluateur)
         └─→ Heuristiques de prédiction
```

### `AIStrategy`
Représente une stratégie d'IA avec 5 poids:
- w0: Win rate
- w1: Accuracy
- w2: Ships destroyed
- w3: Move efficiency
- w4: Concentration de coups

**Opérations**:
- `mutate()`: Modifie légèrement les poids (~10% de chance)
- `crossover()`: Croise deux stratégies

### `GeneticAlgorithm`
Entraîne une population de stratégies:

```dart
final ga = GeneticAlgorithm(
  populationSize: 20,
  generations: 50,
  mutationRate: 0.1,
  crossoverRate: 0.7,
);

ga.train(historyOfGameStats);
final bestStrategy = ga.getBestStrategy();
```

**Processus**:
1. Initialiser population aléatoire
2. Pour chaque génération:
   - Évaluer fitness de chaque stratégie
   - Sélectionner les meilleures (élitisme)
   - Croiser et muter pour la nouvelle génération
3. Retourner la meilleure stratégie

### `MovePredictor`
Prédit le meilleur coup basé sur la stratégie:

```dart
final predictor = MovePredictor(strategy: best, trainingData: stats);
final (row, col) = predictor.predictNextMove(board, gameHistory);
```

**Heuristiques**:
1. **Proximité avec hits**: Si tu as un touché, continue à explorer autour
2. **Densité de navires**: Cible les zones où les navires sont probables
3. **Espacement**: Évite les coups trop proches
4. **Hotspots**: Privilégie les zones centrales (5x5)
5. **Exploration**: Couvre différentes zones du plateau

---

## 📊 Données Collectées par Partie

### Pour chaque joueur:
- ✅ Tous les coups (position + résultat)
- ✅ Timing des coups
- ✅ Précision globale
- ✅ Zones attaquées (heatmap)
- ✅ Patterns d'attaque (linéaire, diagonal, aléatoire)
- ✅ Concentration de coups (variance)
- ✅ Coups par quadrant
- ✅ Durée de la partie
- ✅ Navires détruits

### Analyse Disponible:
```dart
// Heatmap 10x10 des positions attaquées
final hotspots = analytics.getHotspots(playerStats.heatmap, top: 5);

// Patterns détectés
final patterns = analytics.detectMovePatterns(gameStats);
// → horizontal_attacks, vertical_attacks, cross_attacks, random_attacks

// Prédictibilité du joueur (0 = imprévisible, 1 = prévisible)
final predictability = analytics.calculatePredictability(gameStats);

// Coefficient d'adaptation (pour l'IA)
final adaptation = analytics.calculateAdaptationCoefficient(gameStats, 5);
```

---

## 🔄 Flux de Jeu

### 1. Création d'une Partie

```
Joueur 1 + Joueur 2 (ou IA)
         ↓
   GameService.createGame()
         ↓
   Phase SETUP: placement des navires
         ↓
   FirebaseService.createGame() → Firestore
```

### 2. Déroulement du Jeu

```
Chaque tour:
  - Joueur actuel choisit position (row, col)
  - GameService.processMove(game, row, col)
  - Résultat: Hit / Miss / Sunk
  - Mise à jour du jeu
  - FirebaseService.updateGame(game)
  - Si IA: MovePredictor.predictNextMove()
  - Changer de tour
```

### 3. Fin de Partie

```
Tous les navires d'un joueur coulés?
         ↓
   Partie terminée
         ↓
   Calculer les stats: GameStatistics
         ↓
   FirebaseService.saveGameStatistics()
         ↓
   Mises à jour des joueurs (wins/losses)
         ↓
   Si données suffisantes (>5 parties):
      - Réentraîner l'IA (GeneticAlgorithm)
      - Sauvegarder la meilleure stratégie
```

---

## 💾 Structure Firestore

```
users/{userId}
├── name
├── email
├── wins
├── losses
├── gamesPlayed
└── game_stats/{gameId}
    ├── totalMoves
    ├── hits
    ├── accuracy
    ├── won
    └── ...

games/{gameId}
├── player1
├── player2
├── status
├── currentTurnPlayerId
├── winnerId
├── createdAt
└── moves/{moveId}
    ├── row
    ├── col
    ├── result
    └── timestamp

ai_strategies/{userId}
├── id
├── weights [w0, w1, w2, w3, w4]
├── fitness
└── trainingDate
```

---

## 🚀 Prochaines Étapes

- [ ] Implémenter les écrans UI
- [ ] Tests unitaires pour GameService et AnalyticsService
- [ ] Système de matchmaking
- [ ] Notifications en temps réel (Firebase Cloud Messaging)
- [ ] Replay de parties
- [ ] Dashboard analytics
- [ ] Export des données (CSV/JSON)
- [ ] Système de rangs/classements
- [ ] Améliorations IA (Deep Learning?)

---

## 📝 Exemple d'Utilisation Complète

```dart
import 'package:bataille_navale/services/index.dart';
import 'package:bataille_navale/models/index.dart';
import 'package:bataille_navale/ai/index.dart';

void main() async {
  // 1. Initialiser Firebase
  final firebase = FirebaseService();
  await firebase.initialize();

  // 2. Créer/charger les joueurs
  final player1 = Player(
    id: 'user123',
    name: 'Alice',
    email: 'alice@example.com',
    createdAt: DateTime.now(),
  );

  // 3. Créer une partie vs IA
  final gameService = GameService();
  var game = gameService.createGame(
    player1,
    Player(
      id: 'ai',
      name: 'IA',
      email: 'ai@example.com',
      createdAt: DateTime.now(),
    ),
    player2IsAI: true,
  );

  // 4. Placer les navires
  game = game.copyWith(
    board1: gameService.generateRandomShipPlacement(),
    board2: gameService.generateRandomShipPlacement(),
    status: GameStatus.playing,
    currentTurnPlayerId: player1.id,
  );

  // 5. Sauvegarder la partie
  final gameId = await firebase.createGame(game);

  // 6. Boucle de jeu
  while (game.status == GameStatus.playing) {
    if (game.isPlayer1Turn) {
      // Coup du joueur (devrait venir de l'UI)
      final (result, newGame) = gameService.processMove(game, 3, 5);
      game = newGame;
    } else {
      // Coup de l'IA
      final stats = await firebase.getAllGameStats('ai');
      final ga = GeneticAlgorithm();
      ga.train(stats);
      final predictor = MovePredictor(
        strategy: ga.getBestStrategy(),
        trainingData: stats,
      );
      
      final (row, col) = predictor.predictNextMove(
        game.board1,
        game.moves,
      );
      
      final (result, newGame) = gameService.processMove(game, row, col);
      game = newGame;
    }

    await firebase.updateGame(game);
  }

  // 7. Enregistrer les stats
  final p1Stats = gameService.calculateGameStatistics(game, player1.id);
  await firebase.saveGameStatistics(p1Stats);
}
```

---

**Questions?** Consultez la section correspondante ou créez une issue! 🚀
