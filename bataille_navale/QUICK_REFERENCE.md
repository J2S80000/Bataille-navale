# 🚀 Quick Reference - Bataille Navale API

## 🎮 Game Service

### Créer une partie
```dart
final gameService = GameService();
var game = gameService.createGame(player1, player2, player2IsAI: true);
```

### Placer un navire
```dart
// Valider
bool canPlace = gameService.canPlaceShip(
  board, 0, 0, ShipType.carrier, false
);

// Placer
var board = gameService.placeShip(
  board, 0, 0, ShipType.carrier, false
);
```

### Générer un plateau aléatoire
```dart
var board = gameService.generateRandomShipPlacement();
```

### Jouer un coup
```dart
final (result, updatedGame) = gameService.processMove(game, 5, 5);
// result: MoveResult.hit | miss | sunk
```

### Calculer les stats
```dart
final stats = gameService.calculateGameStatistics(game, playerId);
```

---

## 🔥 Firebase Service

### Initialiser
```dart
final firebase = FirebaseService();
await firebase.initialize();
```

### Auth
```dart
// Sign up
await firebase.signUp('email@test.com', 'password', 'Name');

// Sign in
await firebase.signIn('email@test.com', 'password');

// Sign out
await firebase.signOut();

// Current user
final user = firebase.currentUser;
```

### Players
```dart
// Sauvegarder
await firebase.savePlayer(player);

// Récupérer
final player = await firebase.getPlayer(id);

// Profil actuel
final me = await firebase.getCurrentPlayer();
```

### Games
```dart
// Créer
final gameId = await firebase.createGame(game);

// Récupérer
final game = await firebase.getGame(gameId);

// Mettre à jour
await firebase.updateGame(game);

// Historique du joueur
final games = await firebase.getPlayerGames(playerId);

// Stream des parties actives
firebase.watchActiveGames(playerId).listen((games) {
  // MAJ en temps réel
});
```

### Stats
```dart
// Enregistrer stats d'une partie
await firebase.saveGameStatistics(stats);

// Récupérer toutes les stats
final allStats = await firebase.getAllGameStats(playerId);

// Stats agrégées
await firebase.updatePlayerStatisticsAggregate(aggregate);
final agg = await firebase.getPlayerStatisticsAggregate(playerId);
```

### Leaderboards
```dart
// Top 100 joueurs
final top = await firebase.getLeaderboard(limit: 100);

// Top 10 meilleure précision
final topAccuracy = await firebase.getTopAccuracy(limit: 10);
```

---

## 📊 Analytics Service

### Stats agrégées
```dart
final analytics = AnalyticsService();
final stats = await analytics.buildPlayerStatistics(
  playerId, 
  allGameStats
);
```

### Hotspots
```dart
final hotspots = analytics.getHotspots(
  stats.heatmap, 
  top: 5
);
// Returns: List<(row, col, count)>
```

### Patterns
```dart
final patterns = analytics.detectMovePatterns(gameStats);
// Keys: horizontal_attacks, vertical_attacks, cross_attacks, random_attacks
```

### Prédictibilité
```dart
final score = analytics.calculatePredictability(gameStats);
// 0.0 = imprévisible, 1.0 = très prévisible
```

### Adaptation IA
```dart
final coeff = analytics.calculateAdaptationCoefficient(
  gameStats, 
  recentGames: 5
);
// Basé sur win rate récent + accuracy
```

---

## 🤖 Genetic Algorithm

### Entraîner
```dart
final ga = GeneticAlgorithm(
  populationSize: 20,
  generations: 50,
  mutationRate: 0.1,
  crossoverRate: 0.7,
);

ga.train(historyOfGameStats);
final best = ga.getBestStrategy();
```

### Accéder à l'histoire
```dart
final history = ga.getFitnessHistory();
// Returns: List<double> - fitness par génération
```

### Stratégie
```dart
// Mutation
final mutated = strategy.mutate(random);

// Crossover
final child = AIStrategy.crossover(parent1, parent2, random);

// Sérialisation
final json = strategy.toJson();
final restored = AIStrategy.fromJson(json);
```

---

## 🎯 Move Predictor

### Créer
```dart
final predictor = MovePredictor(
  strategy: bestStrategy,
  trainingData: gameStats,
);
```

### Prédire un coup
```dart
final (row, col) = predictor.predictNextMove(
  opponentBoard,
  gameHistory,
);
```

### Heuristiques (poids)
```
w0: Proximité hits        → Continue autour des touchers
w1: Densité navires       → Cible zones probables
w2: Espacement            → Évite redondance
w3: Hotspots              → Privilégie centre 5x5
w4: Exploration           → Couvre quadrants
```

---

## 📦 Models - Quick Create

### Player
```dart
Player(
  id: 'user123',
  name: 'Alice',
  email: 'alice@example.com',
  createdAt: DateTime.now(),
)
```

### Game
```dart
Game(
  id: 'game123',
  player1: alice,
  player2: bob,
  board1: Board.empty(),
  board2: Board.empty(),
  moves: [],
  currentTurnPlayerId: alice.id,
  status: GameStatus.playing,
  createdAt: DateTime.now(),
)
```

### Move
```dart
Move(
  id: 'move123',
  row: 5,
  col: 3,
  result: MoveResult.hit,
  timestamp: DateTime.now(),
  playerId: player.id,
)
```

### Board
```dart
// Vide
var board = Board.empty();

// Avec navires
board = board.addShip(ship);

// Accès
var cell = board.getCell(5, 3);
board = board.updateCell(5, 3, CellState.hit);
```

### Ship
```dart
Ship(
  id: 'ship123',
  type: ShipType.carrier,
  cells: [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4)],
  isVertical: false,
)
```

---

## 🏠 UI Integration (Provider)

### Fournir les services
```dart
MultiProvider(
  providers: [
    Provider<FirebaseService>(create: (_) => FirebaseService()),
    Provider<GameService>(create: (_) => GameService()),
    Provider<AnalyticsService>(create: (_) => AnalyticsService()),
  ],
  child: MyApp(),
)
```

### Utiliser dans un widget
```dart
@override
Widget build(BuildContext context) {
  final firebase = context.read<FirebaseService>();
  final gameService = context.read<GameService>();
  
  // Utiliser les services...
}
```

---

## 📝 Enums

### CellState
```
empty      - Pas touché
hit        - Touché (navire)
miss       - Manqué
ship       - Navire (affichage)
sunk       - Navire coulé
```

### MoveResult
```
miss       - Manqué
hit        - Touché
sunk       - Coulé
invalid    - Coup invalide
```

### GameStatus
```
setup      - Phase de placement
playing    - En cours
finished   - Terminée
abandoned  - Abandonnée
```

### ShipType
```
carrier    - 5 cases
battleship - 4 cases
cruiser    - 3 cases
submarine  - 3 cases
destroyer  - 2 cases
```

---

## 🔍 Common Patterns

### Vérifier si la partie est terminée
```dart
if (game.status == GameStatus.finished) {
  print('Gagnant: ${game.winnerId}');
}
```

### Obtenir les coups du joueur actuel
```dart
final myMoves = game.moves
  .where((m) => m.playerId == game.currentPlayer.id)
  .toList();
```

### Vérifier si c'est mon tour
```dart
if (game.currentTurnPlayerId == myId) {
  // C'est mon tour
}
```

### Obtenir l'adversaire
```dart
final opponent = game.opponent;
```

### Nombre de navires coulés
```dart
final sunk = game.board1.sunkShips; // Plateau adversaire
```

---

## ⚠️ Erreurs Communes

### "Aucun coup possible"
```dart
// La partie est probablement terminée
if (game.status != GameStatus.playing) {
  // Vérifier le statut
}
```

### "Placement de navire invalide"
```dart
// Vérifier avant de placer
if (!gameService.canPlaceShip(board, row, col, type, vertical)) {
  print('Placement invalide');
}
```

### "Coup invalide"
```dart
// La cellule a déjà été attaquée
final cell = board.getCell(row, col);
if (cell.state != CellState.empty) {
  print('Cellule déjà attaquée');
}
```

### "FirebaseCore not initialized"
```dart
// Dans main(), avant runApp():
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp();
```

---

## 🧪 Testing

### Importer pour les tests
```dart
import 'package:test/test.dart';
import 'package:bataille_navale/models/index.dart';
import 'package:bataille_navale/services/game_service.dart';
```

### Exemple test
```dart
test('Ship placement validation', () {
  final gameService = GameService();
  var board = Board.empty();
  
  expect(
    gameService.canPlaceShip(board, 0, 0, ShipType.carrier, false),
    true,
  );
});
```

---

## 📊 Firebase Firestore Structure

```
players/
  {userId}/
    - name: String
    - email: String
    - wins: int
    - losses: int
    - gamesPlayed: int
    - createdAt: DateTime
    
    game_stats/{gameId}/
      - totalMoves: int
      - hits: int
      - accuracy: double
      - won: bool
      - ...
    
    aggregate/stats/
      - totalGames: int
      - winRate: double
      - averageAccuracy: double
      - heatmap: List<int>
      - moveTiming: Map<String, int>

games/
  {gameId}/
    - player1: Player
    - player2: Player
    - board1: Board
    - board2: Board
    - currentTurnPlayerId: String
    - status: String
    - createdAt: DateTime
    - finishedAt: DateTime?
    - winnerId: String?
    
    moves/{moveId}/
      - row: int
      - col: int
      - result: String
      - timestamp: DateTime
      - playerId: String
```

---

**Besoin d'aide?** Consultez `TECHNICAL_GUIDE.md` pour plus de détails!
