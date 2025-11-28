/// Exemple complet d'utilisation de Bataille Navale
///
/// Ce fichier montre comment utiliser tous les services et modèles
/// de l'application Bataille Navale.
library examples;

import 'package:bataille_navale/models/index.dart';
import 'package:bataille_navale/services/index.dart';
import 'package:bataille_navale/ai/index.dart';

/// Exemple 1: Initialiser Firebase et authentifier un utilisateur
Future<void> exampleAuthentication() async {
  final firebase = FirebaseService();
  await firebase.initialize();

  // Inscription
  try {
    final user = await firebase.signUp(
      'alice@example.com',
      'password123',
      'Alice',
    );
    print('✅ Utilisateur créé: ${user?.uid}');
  } catch (e) {
    print('❌ Erreur: $e');
  }

  // Connexion
  try {
    final user = await firebase.signIn(
      'alice@example.com',
      'password123',
    );
    print('✅ Connecté: ${user?.uid}');
  } catch (e) {
    print('❌ Erreur: $e');
  }

  // Récupérer le profil actuel
  final currentPlayer = await firebase.getCurrentPlayer();
  print('Joueur actuel: ${currentPlayer?.name} (${currentPlayer?.email})');
}

/// Exemple 2: Créer et jouer une partie
Future<void> exampleGamePlay() async {
  final firebase = FirebaseService();
  final gameService = GameService();

  // Créer deux joueurs
  final alice = Player(
    id: 'alice_123',
    name: 'Alice',
    email: 'alice@example.com',
    createdAt: DateTime.now(),
  );

  final bob = Player(
    id: 'bob_456',
    name: 'Bob',
    email: 'bob@example.com',
    createdAt: DateTime.now(),
  );

  print('👥 Joueurs créés: ${alice.name} vs ${bob.name}');

  // Créer une partie
  var game = gameService.createGame(alice, bob);
  print('🎮 Partie créée: ${game.id}');

  // Générer les plateaux avec navires aléatoires
  game = game.copyWith(
    board1: gameService.generateRandomShipPlacement(),
    board2: gameService.generateRandomShipPlacement(),
    status: GameStatus.playing,
  );

  print('⚓ Navires placés sur les deux plateaux');

  // Sauvegarder la partie
  final gameId = await firebase.createGame(game);
  print('💾 Partie sauvegardée: $gameId');

  // Simuler 10 coups
  for (int i = 0; i < 10; i++) {
    if (game.status != GameStatus.playing) break;

    final row = (i ~/ 2) % 10;
    final col = (i % 2) * 5;

    try {
      final (result, updatedGame) = gameService.processMove(game, row, col);
      game = updatedGame;

      print('🎯 Coup $i: ($row,$col) → ${result.toString().split('.').last}');
    } catch (e) {
      print('⚠️ Coup invalide: $e');
    }
  }

  // Mettre à jour la partie
  await firebase.updateGame(game);
  print('✅ Partie mise à jour');

  // Calculer les stats
  final statsAlice = gameService.calculateGameStatistics(game, alice.id);
  final statsBob = gameService.calculateGameStatistics(game, bob.id);

  print('''
📊 Statistiques Alice:
  - Total coups: ${statsAlice.totalMoves}
  - Touchers: ${statsAlice.hits}
  - Manqués: ${statsAlice.misses}
  - Précision: ${statsAlice.accuracy.toStringAsFixed(1)}%
  - Navires détruits: ${statsAlice.shipsDestroyed}
''');

  // Enregistrer les stats
  await firebase.saveGameStatistics(statsAlice);
  await firebase.saveGameStatistics(statsBob);
  print('✅ Stats enregistrées');
}

/// Exemple 3: Analyser les données avec Analytics
Future<void> exampleAnalytics() async {
  final firebase = FirebaseService();

  // Récupérer tous les coups d'un joueur
  final playerStats = await firebase.getAllGameStats('alice_123');
  print('📈 ${playerStats.length} parties trouvées pour Alice');

  if (playerStats.isNotEmpty) {
    // Construire les stats agrégées
    final aggregateStats =
        await analytics.buildPlayerStatistics('alice_123', playerStats);

    print('''
📊 Stats agrégées d'Alice:
  - Total parties: ${aggregateStats.totalGames}
  - Victoires: ${aggregateStats.totalWins}
  - Taux de victoire: ${(aggregateStats.winRate * 100).toStringAsFixed(1)}%
  - Précision moyenne: ${aggregateStats.averageAccuracy.toStringAsFixed(1)}%
  - Total coups: ${aggregateStats.totalHits + aggregateStats.totalMisses}
''');

    // Obtenir les zones les plus chaudes
    final hotspots = analytics.getHotspots(aggregateStats.heatmap, top: 5);
    print('\n🔥 Top 5 zones attaquées:');
    for (final (row, col, count) in hotspots) {
      final pos = '${String.fromCharCode(65 + col)}${row + 1}';
      print('  - $pos: $count fois');
    }

    // Analyser les patterns
    final patterns = analytics.detectMovePatterns(playerStats);
    print('\n🎯 Patterns détectés:');
    for (final entry in patterns.entries) {
      print('  - ${entry.key}: ${entry.value?.length ?? 0} coups');
    }

    // Calculer la prédictibilité
    final predictability = analytics.calculatePredictability(playerStats);
    print(
        '\n🎲 Prédictibilité: ${(predictability * 100).toStringAsFixed(1)}%');

    // Sauvegarder les stats agrégées
    await firebase.updatePlayerStatisticsAggregate(aggregateStats);
    print('\n✅ Stats agrégées sauvegardées');
  }
}

/// Exemple 4: Entraîner l'IA avec algorithme génétique
Future<void> exampleAITraining() async {
  final firebase = FirebaseService();
  final analytics = AnalyticsService();

  print('🤖 Entraînement de l\'IA...\n');

  // Récupérer l'historique de l'IA
  final aiStats = await firebase.getAllGameStats('ai_player');

  if (aiStats.isEmpty) {
    print('⚠️ Pas assez de données pour entraîner l\'IA');
    return;
  }

  print('📚 Données: ${aiStats.length} parties');

  // Créer et entraîner l'algorithme génétique
  final ga = GeneticAlgorithm(
    populationSize: 20,
    generations: 50,
    mutationRate: 0.1,
    crossoverRate: 0.7,
  );

  print('🧬 Initialisation de la population...');
  ga.initializePopulation();

  print('⏳ Entraînement en cours...');
  for (int gen = 0; gen < ga.generations; gen++) {
    ga.evaluateFitness(aiStats);

    if (gen % 10 == 0) {
      final best = ga.getBestStrategy();
      print('  Génération $gen: fitness = ${best.fitness.toStringAsFixed(4)}');
    }

    if (gen < ga.generations - 1) {
      ga.evolveGeneration();
    }
  }

  // Afficher la meilleure stratégie
  final bestStrategy = ga.getBestStrategy();
  print('''
✅ Meilleure stratégie trouvée:
  - Fitness: ${bestStrategy.fitness.toStringAsFixed(4)}
  - Poids:
    w0 (win rate):      ${bestStrategy.weights[0].toStringAsFixed(3)}
    w1 (accuracy):      ${bestStrategy.weights[1].toStringAsFixed(3)}
    w2 (ships):         ${bestStrategy.weights[2].toStringAsFixed(3)}
    w3 (efficiency):    ${bestStrategy.weights[3].toStringAsFixed(3)}
    w4 (concentration): ${bestStrategy.weights[4].toStringAsFixed(3)}
''');

  // Afficher la progression de fitness
  final history = ga.getFitnessHistory();
  print('\n📈 Progression du fitness:');
  print('  Génération 0: ${history.first.toStringAsFixed(4)}');
  print('  Génération ${history.length - 1}: ${history.last.toStringAsFixed(4)}');
}

/// Exemple 5: Utiliser le prédicteur pour jouer
Future<void> exampleAIMove() async {
  final firebase = FirebaseService();

  // Récupérer la stratégie entraînée
  final aiStats = await firebase.getAllGameStats('ai_player');

  if (aiStats.isEmpty) {
    print('⚠️ Pas de données pour l\'IA');
    return;
  }

  // Entraîner l'IA
  final ga = GeneticAlgorithm();
  ga.train(aiStats);
  final strategy = ga.getBestStrategy();

  // Créer un prédicteur
  final predictor = MovePredictor(
    strategy: strategy,
    trainingData: aiStats,
  );

  // Créer un plateau de test
  final gameService = GameService();
  var board = gameService.generateRandomShipPlacement();

  // Prédire le prochain coup
  print('🎮 L\'IA joue...\n');

  for (int i = 0; i < 5; i++) {
    final (row, col) = predictor.predictNextMove(board, []);
    final pos = '${String.fromCharCode(65 + col)}${row + 1}';
    print('  Coup $i: Attaquer $pos');
  }
}

/// Exemple 6: Afficher le leaderboard
Future<void> exampleLeaderboard() async {
  final firebase = FirebaseService();

  // Top joueurs par wins
  final topPlayers = await firebase.getLeaderboard(limit: 10);

  print('🏆 Leaderboard Top 10:\n');
  for (int i = 0; i < topPlayers.length; i++) {
    final player = topPlayers[i];
    final winRate = player.gamesPlayed > 0
        ? ((player.wins / player.gamesPlayed) * 100).toStringAsFixed(1)
        : '0.0';
    print(
        '${i + 1}. ${player.name} - ${player.wins}W/${player.losses}L (${winRate}%)');
  }
}

/// Exemple 7: Placement manuel de navires
Future<void> exampleManualShipPlacement() async {
  final gameService = GameService();

  var board = Board.empty();

  print('📍 Placement manuel de navires\n');

  // Essayer de placer un porte-avions horizontalement
  if (gameService.canPlaceShip(board, 0, 0, ShipType.carrier, false)) {
    board = gameService.placeShip(board, 0, 0, ShipType.carrier, false);
    print('✅ Porte-avions placé à A1-E1');
  }

  // Essayer de placer un croiseur verticalement
  if (gameService.canPlaceShip(board, 2, 5, ShipType.battleship, true)) {
    board = gameService.placeShip(board, 2, 5, ShipType.battleship, true);
    print('✅ Croiseur placé à F3-F6');
  }

  // Placer les autres navires aléatoirement
  final shipTypes = ShipType.values
      .where((type) =>
          type != ShipType.carrier &&
          type != ShipType.battleship)
      .toList();

  for (final shipType in shipTypes) {
    bool placed = false;
    for (int row = 0; row < 10 && !placed; row++) {
      for (int col = 0; col < 10 && !placed; col++) {
        if (gameService.canPlaceShip(board, row, col, shipType, false)) {
          board = gameService.placeShip(board, row, col, shipType, false);
          placed = true;
        }
      }
    }
  }

  print('\n✅ Plateau complètement rempli');
  print('Total navires: ${board.ships.length}');
}

/// Fonction principale: exécuter tous les exemples
void main() async {
  print('''
═══════════════════════════════════════════════════════════════
  🎮 EXEMPLES D'UTILISATION - BATAILLE NAVALE
═══════════════════════════════════════════════════════════════
''');

  try {
    print('\n### Exemple 1: Authentification\n');
    // await exampleAuthentication();

    print('\n\n### Exemple 2: Créer et jouer une partie\n');
    // await exampleGamePlay();

    print('\n\n### Exemple 3: Analyser les données\n');
    // await exampleAnalytics();

    print('\n\n### Exemple 4: Entraîner l\'IA\n');
    // await exampleAITraining();

    print('\n\n### Exemple 5: Prédire un coup avec l\'IA\n');
    // await exampleAIMove();

    print('\n\n### Exemple 6: Voir le leaderboard\n');
    // await exampleLeaderboard();

    print('\n\n### Exemple 7: Placer les navires manuellement\n');
    await exampleManualShipPlacement();

    print('''

═══════════════════════════════════════════════════════════════
  ✅ Exemples terminés!
═══════════════════════════════════════════════════════════════
''');
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
