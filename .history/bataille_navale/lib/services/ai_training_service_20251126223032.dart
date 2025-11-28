import '../models/index.dart';
import '../ai/genetic_algorithm.dart';
import 'simulation_service.dart';
import 'mongodb_service.dart';
import 'ai_evolution_service.dart';
import 'dart:math';

/// Service d'entraînement automatique de l'IA via simulations
class AITrainingService {
  /// Configuration par défaut pour l'entraînement
  static const int DEFAULT_BATCH_SIZE = 50;
  static const int DEFAULT_GENERATIONS = 10;
  static const double DEFAULT_WIN_RATE_TARGET = 0.70; // 70% de victoires cible

  /// Lance un entraînement complet de l'IA
  /// Retourne la meilleure stratégie trouvée
  static Future<AIStrategy> trainAI({
    required String aiId,
    required AIStrategy initialStrategy,
    required Function(String) onProgress, // Pour logger la progression
    int batchSize = DEFAULT_BATCH_SIZE,
    int generations = DEFAULT_GENERATIONS,
    double winRateTarget = DEFAULT_WIN_RATE_TARGET,
  }) async {
    print('🤖 [TRAINING] Démarrage entraînement IA: $aiId');
    print('   Batch: $batchSize parties | Générations: $generations');
    print('   Target: ${(winRateTarget * 100).toStringAsFixed(0)}% victoires');

    final mongoService = MongoDBService();
    await mongoService.initialize();

    var currentStrategy = initialStrategy;
    AIStrategy bestStrategy = initialStrategy;
    double bestWinRate = 0;
    final trainingHistory = <Map<String, dynamic>>[];

    for (int gen = 0; gen < generations; gen++) {
      onProgress('🔄 Génération ${gen + 1}/$generations - Simulation de $batchSize parties...');
      print('   [GEN $gen] Simulation batch...');

      // Simuler des parties avec la stratégie actuelle
      final gameResults = await SimulationService.simulateGames(
        count: batchSize,
        playerId: aiId,
        opponentId: 'training_opponent_gen$gen',
        onProgress: (current, total) {
          // Silencieux pendant les simulations
        },
      );

      // Analyser les résultats
      final wins = gameResults.where((g) => g.won).length;
      final winRate = wins / gameResults.length;
      final avgAccuracy = gameResults.fold(0.0, (sum, g) => sum + g.accuracy) / gameResults.length;
      final totalHits = gameResults.fold(0, (sum, g) => sum + g.hits);
      final totalMoves = gameResults.fold(0, (sum, g) => sum + g.totalMoves);

      print('   [GEN $gen] Résultats: $wins/$batchSize wins (${(winRate * 100).toStringAsFixed(1)}%)');
      print('   [GEN $gen] Précision: ${avgAccuracy.toStringAsFixed(1)}% | Hits: $totalHits/$totalMoves');

      // Sauvegarder les résultats dans MongoDB en arrière-plan
      _saveTrainingResults(aiId, gen, gameResults, mongoService);

      // Améliorer la stratégie basée sur les résultats
      currentStrategy = AIEvolutionService.improveStrategy(
        currentStrategy: currentStrategy,
        recentGames: gameResults,
        generation: gen,
      );

      // Tracker la meilleure stratégie
      if (winRate > bestWinRate) {
        bestWinRate = winRate;
        bestStrategy = currentStrategy;
        print('   [GEN $gen] ✓ Nouvelle meilleure stratégie trouvée! (${(bestWinRate * 100).toStringAsFixed(1)}%)');
      }

      // Construire l'historique
      final report = AIEvolutionService.generateEvolutionReport(
        allGames: gameResults,
        generationNumber: gen,
        bestWinRate: bestWinRate,
      );
      trainingHistory.add(report);

      onProgress(
        '✓ Génération ${gen + 1}/$generations - '
        'Victoires: ${(winRate * 100).toStringAsFixed(1)}% | '
        'Meilleur: ${(bestWinRate * 100).toStringAsFixed(1)}%',
      );

      // Vérifier si on a atteint la cible
      if (winRate >= winRateTarget) {
        print('   [TRAINING] 🎯 Cible atteinte! ($winRate >= $winRateTarget)');
        onProgress('✓ Cible atteinte! L\'IA a {{${(winRate * 100).toStringAsFixed(1)}% de victoires');
        break;
      }

      // Pause légère entre générations
      await Future.delayed(Duration(milliseconds: 500));
    }

    // Sauvegarder la meilleure stratégie
    await _saveBestStrategy(aiId, bestStrategy, bestWinRate, trainingHistory, mongoService);

    print('🤖 [TRAINING] ✓ Entraînement terminé!');
    print('   Meilleure stratégie: ${bestStrategy.id}');
    print('   Taux de victoire: ${(bestWinRate * 100).toStringAsFixed(1)}%');

    return bestStrategy;
  }

  /// Lance un entraînement continu qui s'exécute régulièrement
  static Future<void> startContinuousTraining({
    required String aiId,
    required AIStrategy currentStrategy,
    required int intervalHours,
    required Function(String) onProgress,
  }) async {
    print('🔄 [CONTINUOUS] Entraînement continu lancé pour $aiId (tous les ${intervalHours}h)');

    while (true) {
      final now = DateTime.now();
      onProgress('⏰ Prochain entraînement à ${now.add(Duration(hours: intervalHours))}');

      // Attendre l'intervalle spécifié
      await Future.delayed(Duration(hours: intervalHours));

      // Lancer l'entraînement
      final improvedStrategy = await trainAI(
        aiId: aiId,
        initialStrategy: currentStrategy,
        onProgress: onProgress,
        batchSize: 30,
        generations: 5,
      );

      // Mettre à jour la stratégie actuelle
      // (À intégrer avec le système d'IA principal)
    }
  }

  /// Analyse les performances de l'IA et suggère des améliorations
  static Future<Map<String, dynamic>> analyzePerformance({
    required String aiId,
    required MongoDBService mongoService,
  }) async {
    try {
      // Récupérer l'historique des parties
      final gameStats = await mongoService.getPlayerStatistics(aiId);

      if (gameStats.isEmpty) {
        return {
          'status': 'no_data',
          'message': 'Aucune donnée d\'entraînement',
        };
      }

      // Analyser les dernières 20 parties
      final recentGames = gameStats.length > 20
          ? gameStats.sublist(gameStats.length - 20)
          : gameStats;

      final wins = recentGames.where((g) => g.won).length;
      final winRate = wins / recentGames.length;
      final avgAccuracy = recentGames.fold(0.0, (sum, g) => sum + g.accuracy) / recentGames.length;
      final avgDuration = recentGames.fold(0, (sum, g) => sum + g.gameDuration.inSeconds) / recentGames.length;

      // Générer des suggestions
      final suggestions = <String>[];

      if (winRate < 0.4) {
        suggestions.add('Stratégie défensive trop faible - augmenter exploration');
      } else if (winRate > 0.8) {
        suggestions.add('Excellentes performances - IA bien entraînée');
      }

      if (avgAccuracy < 35) {
        suggestions.add('Précision faible - améliorer sélection des cibles');
      }

      if (avgDuration > 200) {
        suggestions.add('Parties longues - optimiser l\'algorithme de recherche');
      }

      return {
        'status': 'success',
        'winRate': (winRate * 100).toStringAsFixed(1),
        'avgAccuracy': avgAccuracy.toStringAsFixed(1),
        'totalGames': gameStats.length,
        'suggestions': suggestions,
        'lastUpdate': gameStats.last.recordedAt.toIso8601String(),
      };
    } catch (e) {
      print('Erreur analyse performance: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Sauvegarde les résultats d'un batch d'entraînement (en arrière-plan)
  static Future<void> _saveTrainingResults(
    String aiId,
    int generation,
    List<GameStatistics> gameResults,
    MongoDBService mongoService,
  ) async {
    try {
      for (final stat in gameResults) {
        await mongoService.saveGameStatistics(stat);
      }
      print('   [GEN $generation] ✓ ${gameResults.length} résultats sauvegardés MongoDB');
    } catch (e) {
      print('   [ERROR] Sauvegarde MongoDB échouée: $e');
    }
  }

  /// Sauvegarde la meilleure stratégie trouvée
  static Future<void> _saveBestStrategy(
    String aiId,
    AIStrategy strategy,
    double winRate,
    List<Map<String, dynamic>> history,
    MongoDBService mongoService,
  ) async {
    try {
      final strategyData = {
        'aiId': aiId,
        'strategyId': strategy.id,
        'weights': strategy.weights,
        'winRate': winRate,
        'timestamp': DateTime.now().toIso8601String(),
        'history': history,
      };

      // Sauvegarder comme game state personnalisé
      await mongoService.saveGameState(strategyData);
      print('✓ Meilleure stratégie sauvegardée: ${strategy.id}');
    } catch (e) {
      print('Erreur sauvegarde stratégie: $e');
    }
  }

  /// Génère un rapport d'entraînement lisible
  static String generateTrainingReport(
    Map<String, dynamic> analysis,
    AIStrategy bestStrategy,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('📊 RAPPORT D\'ENTRAÎNEMENT IA');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('');

    if (analysis['status'] == 'success') {
      buffer.writeln('✓ Taux de victoire: ${analysis['winRate']}%');
      buffer.writeln('✓ Précision moyenne: ${analysis['avgAccuracy']}%');
      buffer.writeln('✓ Parties analysées: ${analysis['totalGames']}');
      buffer.writeln('');

      if (analysis['suggestions'].isNotEmpty) {
        buffer.writeln('💡 Suggestions:');
        for (final suggestion in analysis['suggestions']) {
          buffer.writeln('  • $suggestion');
        }
      }
    } else {
      buffer.writeln('⚠ ${analysis['message']}');
    }

    buffer.writeln('');
    buffer.writeln('🔧 Stratégie: ${bestStrategy.id}');
    buffer.writeln('Poids: ${bestStrategy.weights.map((w) => w.toStringAsFixed(2)).join(', ')}');
    buffer.writeln('═══════════════════════════════════════');

    return buffer.toString();
  }
}
