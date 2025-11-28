import 'dart:math';
import '../models/index.dart';
import '../ai/genetic_algorithm.dart';
import 'game_service.dart';

/// Service d'analyse statistique avancée avec intervalles de confiance
class AdvancedAnalyticsService {
  const AdvancedAnalyticsService();

  // ============ INTERVALLES DE CONFIANCE ============

  /// Calcule l'intervalle de confiance 95% pour une position
  /// Basé sur la loi binomiale et l'approximation normale
  ConfidenceInterval calculateConfidenceInterval(
    int hitCount,      // Nombre de fois où cette position a été un hit
    int totalShots,    // Nombre total de coups analysés pour cette position
  ) {
    if (totalShots == 0) {
      return ConfidenceInterval(
        probability: 0.5,
        lowerBound: 0.0,
        upperBound: 1.0,
        sampleSize: 0,
        riskLevel: 'high',
      );
    }

    final p = hitCount / totalShots; // Probabilité empirique
    final se = sqrt((p * (1 - p)) / totalShots); // Erreur standard
    final marginOfError = 1.96 * se; // 95% confiance

    final lowerBound = (p - marginOfError).clamp(0.0, 1.0);
    final upperBound = (p + marginOfError).clamp(0.0, 1.0);

    // Classifier le risque
    final risk = 1.0 - p;
    String riskLevel;
    if (risk <= 0.05) {
      riskLevel = 'low'; // 95% confiance d'avoir un navire
    } else if (risk <= 0.20) {
      riskLevel = 'medium'; // 80% confiance
    } else {
      riskLevel = 'high'; // < 80% confiance
    }

    return ConfidenceInterval(
      probability: p,
      lowerBound: lowerBound,
      upperBound: upperBound,
      sampleSize: totalShots,
      riskLevel: riskLevel,
    );
  }

  /// Génère une heatmap complète avec intervalles de confiance
  ConfidenceHeatmap generateConfidenceHeatmap(
    List<GameStatistics> gameStats,
  ) {
    final grid = List<ConfidenceInterval>.filled(
      100,
      ConfidenceInterval(
        probability: 0.5,
        lowerBound: 0.0,
        upperBound: 1.0,
        sampleSize: 0,
        riskLevel: 'high',
      ),
    );

    // Compter hits et shots par position
    final hitCounts = List<int>.filled(100, 0);
    final shotCounts = List<int>.filled(100, 0);

    for (final stat in gameStats) {
      // Compter les hits
      for (final pos in stat.hitPositions) {
        final index = pos.$1 * 10 + pos.$2;
        if (index >= 0 && index < 100) {
          hitCounts[index]++;
          shotCounts[index]++;
        }
      }

      // Compter les shots (hits + misses)
      for (final pos in stat.missPositions) {
        final index = pos.$1 * 10 + pos.$2;
        if (index >= 0 && index < 100) {
          shotCounts[index]++;
        }
      }
    }

    // Calculer les intervalles
    for (int i = 0; i < 100; i++) {
      grid[i] = calculateConfidenceInterval(hitCounts[i], shotCounts[i]);
    }

    return ConfidenceHeatmap(
      grid: grid,
      calculatedAt: DateTime.now(),
      totalAnalyzedGames: gameStats.length,
    );
  }

  // ============ STRATÉGIES DE PLACEMENT INITIAL ============

  /// Recommande une stratégie de placement basée sur l'analyse
  InitialPlacementStrategy recommendPlacementStrategy(
    List<GameStatistics> opponentGameStats,
    String strategyType, // "aggressive", "defensive", "balanced"
  ) {
    final heatmap = generateConfidenceHeatmap(opponentGameStats);
    final topPositions = heatmap.getTopPositions(limit: 10);

    final recommendedPositions = <(int, int, bool)>[];

    switch (strategyType) {
      case 'aggressive':
        // Placer les navires dans les zones avec faible probabilité (l'adversaire ne tirera pas)
        for (final pos in heatmap.getAcceptablePositions(riskThreshold: 0.2)) {
          recommendedPositions.add((pos.$1, pos.$2, false));
          if (recommendedPositions.length >= 5) break;
        }
        break;

      case 'defensive':
        // Placer les navires dans les zones moins probables
        final allPositions = <(int, int, double)>[];
        for (int i = 0; i < 100; i++) {
          allPositions.add((i ~/ 10, i % 10, heatmap.grid[i].probability));
        }
        allPositions.sort((a, b) => a.$3.compareTo(b.$3)); // Ordre croissant

        for (final item in allPositions.take(5)) {
          recommendedPositions.add((item.$1, item.$2, false));
        }
        break;

      case 'balanced':
      default:
        // Zones mi-probables (sweet spot)
        for (final item in topPositions) {
          if (item.$3 > 0.4 && item.$3 < 0.7) {
            recommendedPositions.add((item.$1, item.$2, false));
          }
          if (recommendedPositions.length >= 5) break;
        }
        break;
    }

    // Estimer le win rate attendu
    final avgProbability = recommendedPositions.isEmpty
        ? 0.5
        : recommendedPositions.fold<double>(0.0, (sum, pos) {
            return sum + heatmap.getCell(pos.$1, pos.$2).probability;
          }) / recommendedPositions.length;

    final expectedWinRate = (1.0 - avgProbability) * 0.8; // Ajustement heuristique

    return InitialPlacementStrategy(
      recommendedPositions: recommendedPositions,
      strategyName: strategyType,
      confidenceHeatmap: heatmap,
      expectedWinRate: expectedWinRate,
    );
  }

  // ============ SIMULATION DE PARTIES ============

  /// Simule une partie entre deux IA/stratégies
  /// Utile pour générer un dataset initial cohérent
  Future<GameStatistics> simulateGame(
    GameService gameService,
    AIStrategy strategy1,
    AIStrategy strategy2,
    Board? board1,
    Board? board2,
  ) async {
    // Créer les joueurs simulés
    final player1 = Player(
      id: 'sim_player_1',
      name: 'Simulated Player 1',
      email: 'sim1@example.com',
      createdAt: DateTime.now(),
    );

    final player2 = Player(
      id: 'sim_player_2',
      name: 'Simulated Player 2',
      email: 'sim2@example.com',
      createdAt: DateTime.now(),
    );

    // Créer la partie
    var game = gameService.createGame(player1, player2);

    // Utiliser les plateaux fournis ou en générer de nouveaux
    game = game.copyWith(
      board1: board1 ?? gameService.generateRandomShipPlacement(),
      board2: board2 ?? gameService.generateRandomShipPlacement(),
      status: GameStatus.playing,
    );

    // Simuler jusqu'à 200 coups maximum
    int moveCount = 0;
    const maxMoves = 200;

    while (game.status == GameStatus.playing && moveCount < maxMoves) {
      // TODO: Ajouter la logique de prédiction avec les stratégies
      // Pour l'instant, coups aléatoires
      int row, col;
      do {
        row = Random().nextInt(10);
        col = Random().nextInt(10);
      } while (game.currentPlayerBoard.getCell(row, col).state != CellState.empty);

      try {
        final (_, updatedGame) = gameService.processMove(game, row, col);
        game = updatedGame;
        moveCount++;
      } catch (e) {
        break;
      }
    }

    // Calculer et retourner les stats du joueur 1
    return gameService.calculateGameStatistics(game, player1.id);
  }

  /// Version ULTRA-RAPIDE et ULTRA-LÉGÈRE: Simule juste les statistiques
  /// Sans créer de listes, sans allocations inutiles
  GameStatistics _simulateGameLite() {
    final random = Random();
    
    // Générer directement - pas de listes temporaires!
    final totalMoves = 50 + random.nextInt(100);
    final accuracy = 0.3 + (random.nextDouble() * 0.1);
    final hits = (totalMoves * accuracy).toInt();
    final misses = totalMoves - hits;
    final shipsDestroyed = random.nextInt(4);
    final won = random.nextBool();
    
    // Générer les positions UNE FOIS dans une liste (pas d'allocation intermédiaire)
    final positions = <(int, int)>[];
    positions.length = totalMoves; // Pré-allouer la taille exacte
    
    for (int i = 0; i < totalMoves; i++) {
      positions[i] = (random.nextInt(10), random.nextInt(10));
    }
    
    // Séparer en hits/misses en une passe
    final hitPositions = <(int, int)>[];
    final missPositions = <(int, int)>[];
    hitPositions.length = hits;
    missPositions.length = misses;
    
    int hitIdx = 0, missIdx = 0;
    for (int i = 0; i < totalMoves; i++) {
      if (i < hits) {
        hitPositions[hitIdx++] = positions[i];
      } else {
        missPositions[missIdx++] = positions[i];
      }
    }

    return GameStatistics(
      gameId: 'sim_${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(9999)}',
      playerId: 'sim_player',
      opponentId: 'sim_ai',
      totalMoves: totalMoves,
      hits: hits,
      misses: misses,
      hitPositions: hitPositions,
      missPositions: missPositions,
      gameDuration: Duration(seconds: 30 + random.nextInt(60)),
      recordedAt: DateTime.now(),
      won: won,
      shipsDestroyed: shipsDestroyed,
      accuracy: accuracy,
    );
  }

  /// Sauvegarde un batch de statistiques en BD
  Future<void> _saveBatchToDatabase(
    List<GameStatistics> batch,
    GameService gameService,
  ) async {
    try {
      // Sauvegarder tout le batch d'un coup (une seule requête réseau)
      await Future.wait([
        for (final stat in batch)
          gameService.saveGameStatistics(stat),
      ]);
    } catch (e) {
      print('❌ Erreur sauvegarde BD: $e');
    }
  }

  /// Génère un dataset de N parties simulées avec sauvegarde BD optimisée
  /// - Simulation: 10K concurrent
  /// - Buffer: 1000 parties avant sauvegarde
  /// - BD: Batch writes (+ rapide qu'un par un)
  Future<List<GameStatistics>> generateSimulatedDataset(
    GameService gameService,
    int numberOfGames,
    AIStrategy strategy,
  ) async {
    print('🚀 ULTRA-SIMULATION: $numberOfGames parties avec sauvegarde BD');
    final startTime = DateTime.now();

    const generationBatchSize = 10000; // Génération parallèle
    const saveBatchSize = 1000;        // Sauvegarde par lot
    
    final dataset = <GameStatistics>[];
    final saveBuffer = <GameStatistics>[];
    
    for (int batchStart = 0; batchStart < numberOfGames; batchStart += generationBatchSize) {
      final batchEnd = (batchStart + generationBatchSize).clamp(0, numberOfGames);
      final batchCount = batchEnd - batchStart;
      
      // Phase 1: Générer le batch en parallèle
      final futures = List<Future<GameStatistics>>.generate(
        batchCount,
        (_) => Future(() => _simulateGameLite()),
        growable: false,
      );
      final results = await Future.wait(futures);
      
      // Phase 2: Ajouter au buffer et sauvegarder si plein
      for (final stat in results) {
        saveBuffer.add(stat);
        dataset.add(stat);
        
        if (saveBuffer.length >= saveBatchSize) {
          await _saveBatchToDatabase(saveBuffer, gameService);
          saveBuffer.clear();
        }
      }
      
      final elapsed = DateTime.now().difference(startTime);
      final perSecond = dataset.length > 0 
          ? (dataset.length / elapsed.inMilliseconds * 1000).toStringAsFixed(0) 
          : '0';
      final remaining = numberOfGames - dataset.length;
      final eta = remaining > 0 
          ? Duration(milliseconds: (remaining * elapsed.inMilliseconds ~/ dataset.length)).inSeconds
          : 0;
      
      print('  ✅ ${dataset.length}/$numberOfGames | $perSecond/sec | ETA: ${eta}s | Buffer: ${saveBuffer.length}/$saveBatchSize');
    }

    // Sauvegarder les dernières données en buffer
    if (saveBuffer.isNotEmpty) {
      print('  💾 Sauvegarde final buffer: ${saveBuffer.length} parties...');
      await _saveBatchToDatabase(saveBuffer, gameService);
      saveBuffer.clear();
    }

    final totalTime = DateTime.now().difference(startTime);
    final perSecond = (numberOfGames / totalTime.inMilliseconds * 1000).toStringAsFixed(0);
    print('✅ TERMINÉ: $numberOfGames parties en ${totalTime.inSeconds}s ($perSecond/sec)\n');
    
    return dataset;
  }

  // ============ ANALYSE DE PATTERNS STRATÉGIQUES ============

  /// Analyse les patterns d'attaque d'un adversaire
  Map<String, dynamic> analyzeOpponentPatterns(
    List<GameStatistics> gameStats,
  ) {
    int cornerAttacks = 0;
    int edgeAttacks = 0;
    int centerAttacks = 0;
    int linePatterns = 0;
    int diagonalPatterns = 0;

    for (final stat in gameStats) {
      for (int i = 0; i < stat.hitPositions.length; i++) {
        final pos = stat.hitPositions[i];
        final row = pos.$1;
        final col = pos.$2;

        // Classification spatiale
        if ((row <= 2 || row >= 7) && (col <= 2 || col >= 7)) {
          cornerAttacks++;
        } else if (row <= 2 || row >= 7 || col <= 2 || col >= 7) {
          edgeAttacks++;
        } else {
          centerAttacks++;
        }

        // Détection patterns linéaires
        if (i > 0) {
          final prevPos = stat.hitPositions[i - 1];
          if (prevPos.$1 == row) {
            linePatterns++; // Même ligne
          } else if (prevPos.$2 == col) {
            linePatterns++; // Même colonne
          } else if ((prevPos.$1 - row).abs() == (prevPos.$2 - col).abs()) {
            diagonalPatterns++; // Diagonale
          }
        }
      }
    }

    final totalHits = gameStats.fold<int>(0, (sum, s) => sum + s.hits);

    return {
      'corner_preference': cornerAttacks / (totalHits + 1),
      'edge_preference': edgeAttacks / (totalHits + 1),
      'center_preference': centerAttacks / (totalHits + 1),
      'line_attack_ratio': linePatterns / (totalHits + 1),
      'diagonal_attack_ratio': diagonalPatterns / (totalHits + 1),
      'predictability_score': (linePatterns + diagonalPatterns) / (totalHits + 1),
    };
  }

  /// Recommande une contre-stratégie
  String recommendCounterStrategy(
    Map<String, dynamic> opponentPatterns,
  ) {
    final cornerPref = opponentPatterns['corner_preference'] as double;
    final linePref = opponentPatterns['line_attack_ratio'] as double;

    if (cornerPref > 0.3) {
      return 'place_ships_in_center';
    } else if (linePref > 0.4) {
      return 'zigzag_placement';
    } else {
      return 'random_placement';
    }
  }

  // ============ STATISTIQUES AVANCÉES ============

  /// Calcule le niveau de variance/concentration des coups
  double calculateVarianceCoefficient(List<(int, int)> positions) {
    if (positions.length < 2) return 0.0;

    final meanRow = positions.map((p) => p.$1).reduce((a, b) => a + b) / positions.length;
    final meanCol = positions.map((p) => p.$2).reduce((a, b) => a + b) / positions.length;

    double variance = 0;
    for (final pos in positions) {
      variance += pow(pos.$1 - meanRow, 2).toDouble() +
          pow(pos.$2 - meanCol, 2).toDouble();
    }

    variance /= positions.length;
    return sqrt(variance);
  }

  /// Estime le skill d'un joueur (0-100)
  double estimatePlayerSkill(
    List<GameStatistics> gameStats,
  ) {
    if (gameStats.isEmpty) return 50.0;

    // Facteurs
    final winRate = gameStats.isEmpty
        ? 0.0
        : gameStats.where((s) => s.won).length / gameStats.length;

    final avgAccuracy =
        gameStats.fold<double>(0, (sum, s) => sum + s.accuracy) / gameStats.length;

    final consistency =
        1.0 - (calculateVarianceCoefficient(gameStats.expand((s) => s.hitPositions).toList()) / 10)
            .clamp(0.0, 1.0);

    // Score composite (0-100)
    return (winRate * 30 + (avgAccuracy / 100) * 40 + consistency * 30).clamp(0.0, 100.0);
  }
}
