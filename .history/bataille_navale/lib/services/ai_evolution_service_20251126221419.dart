import '../models/index.dart';
import 'dart:math';

/// Service pour l'évolution et l'amélioration de l'IA basée sur les simulations
class AIEvolutionService {
  static final Random _random = Random();

  /// Analyse les résultats des simulations et génère une meilleure stratégie
  /// 
  /// Plus de victoires = IA s'améliore progressivement
  /// Plus de défaites = Ajustements tactiques
  static AIStrategy improveStrategy({
    required AIStrategy currentStrategy,
    required List<GameStatistics> recentGames,
    required int generation,
  }) {
    if (recentGames.isEmpty) return currentStrategy;

    // Calculer le taux de victoire
    final wins = recentGames.where((g) => g.won).length;
    final winRate = (wins / recentGames.length);
    final avgAccuracy = recentGames.fold(0.0, (sum, g) => sum + g.accuracy) / recentGames.length;

    // Weights: [proximité, densité, espacement, hotspots, exploration]
    var newWeights = [...currentStrategy.weights];

    // Si l'IA gagne < 30%, augmenter exploration
    if (winRate < 0.3) {
      newWeights[4] = (newWeights[4] + 0.15).clamp(0.0, 1.0);
      newWeights[0] = (newWeights[0] - 0.05).clamp(0.0, 1.0);
    }
    // Si l'IA gagne >= 70%, renforcer ce qui marche
    else if (winRate >= 0.7) {
      // Renforcer proximité et hotspots
      newWeights[0] = (newWeights[0] + 0.1).clamp(0.0, 1.0);
      newWeights[3] = (newWeights[3] + 0.1).clamp(0.0, 1.0);
      newWeights[4] = (newWeights[4] - 0.05).clamp(0.0, 1.0);
    }
    // Entre 30% et 70%, ajustements fins
    else {
      // Augmenter densité si précision faible
      if (avgAccuracy < 40) {
        newWeights[1] = (newWeights[1] + 0.1).clamp(0.0, 1.0);
      }
      // Augmenter hotspots si précision bonne
      else if (avgAccuracy > 50) {
        newWeights[3] = (newWeights[3] + 0.05).clamp(0.0, 1.0);
      }
    }

    // Normaliser les weights
    final sum = newWeights.reduce((a, b) => a + b);
    newWeights = newWeights.map((w) => w / sum).toList();

    // Ajouter léger bruit pour éviter les minima locaux
    if (generation > 5) {
      for (int i = 0; i < newWeights.length; i++) {
        final noise = (_random.nextDouble() - 0.5) * 0.05;
        newWeights[i] = (newWeights[i] + noise).clamp(0.0, 1.0);
      }
      // Re-normaliser après bruit
      final newSum = newWeights.reduce((a, b) => a + b);
      newWeights = newWeights.map((w) => w / newSum).toList();
    }

    return AIStrategy(
      id: '${currentStrategy.id}_gen${generation}',
      weights: newWeights,
    );
  }

  /// Sélectionne la meilleure stratégie parmi un pool de candidats
  static AIStrategy selectBestStrategy({
    required List<AIStrategy> strategies,
    required Map<String, List<GameStatistics>> strategyResults,
  }) {
    AIStrategy bestStrategy = strategies.first;
    double bestWinRate = 0;

    for (final strategy in strategies) {
      final games = strategyResults[strategy.id] ?? [];
      if (games.isEmpty) continue;

      final winRate = games.where((g) => g.won).length / games.length;
      if (winRate > bestWinRate) {
        bestWinRate = winRate;
        bestStrategy = strategy;
      }
    }

    return bestStrategy;
  }

  /// Croise deux stratégies parentales pour générer une descendance
  static AIStrategy crossover(AIStrategy parent1, AIStrategy parent2) {
    final newWeights = <double>[];
    for (int i = 0; i < parent1.weights.length; i++) {
      // Prendre aléatoirement d'un parent ou interpoler
      if (_random.nextBool()) {
        newWeights.add(parent1.weights[i]);
      } else {
        newWeights.add(parent2.weights[i]);
      }
    }
    return AIStrategy(
      id: 'crossover_${DateTime.now().millisecondsSinceEpoch}',
      weights: newWeights,
    );
  }

  /// Mutate une stratégie avec variation aléatoire
  static AIStrategy mutate(AIStrategy strategy, {double mutationRate = 0.1}) {
    final newWeights = strategy.weights.map((w) {
      if (_random.nextDouble() < mutationRate) {
        return (w + (_random.nextDouble() - 0.5) * 0.2).clamp(0.0, 1.0);
      }
      return w;
    }).toList();

    // Normaliser
    final sum = newWeights.reduce((a, b) => a + b);
    final normalized = newWeights.map((w) => w / sum).toList();

    return AIStrategy(
      id: '${strategy.id}_mut',
      weights: normalized,
    );
  }

  /// Lance une génération complète d'évolution
  /// Retourne la meilleure stratégie trouvée
  static Future<AIStrategy> evolveGeneration({
    required List<AIStrategy> currentPopulation,
    required Function(AIStrategy) evaluateStrategy,
    required int populationSize,
  }) async {
    // Évaluer la génération actuelle
    final results = <String, double>{};
    for (final strategy in currentPopulation) {
      results[strategy.id] = (await evaluateStrategy(strategy));
    }

    // Sélectionner les meilleurs (top 30%)
    final sortedStrategies = currentPopulation.toList();
    sortedStrategies.sort((a, b) => (results[b.id] ?? 0).compareTo(results[a.id] ?? 0));
    
    final eliteSize = (populationSize * 0.3).toInt();
    final elite = sortedStrategies.take(eliteSize).toList();

    // Générer nouvelle population via crossover et mutation
    final newPopulation = <AIStrategy>[...elite];
    while (newPopulation.length < populationSize) {
      final parent1 = elite[_random.nextInt(elite.length)];
      final parent2 = elite[_random.nextInt(elite.length)];
      
      var offspring = crossover(parent1, parent2);
      
      // 50% chance de mutation
      if (_random.nextDouble() < 0.5) {
        offspring = mutate(offspring);
      }
      
      newPopulation.add(offspring);
    }

    return sortedStrategies.first;
  }

  /// Génère un rapport de progression d'évolution
  static Map<String, dynamic> generateEvolutionReport({
    required List<GameStatistics> allGames,
    required int generationNumber,
    required double bestWinRate,
  }) {
    final totalGames = allGames.length;
    final wins = allGames.where((g) => g.won).length;
    final avgAccuracy = allGames.fold(0.0, (sum, g) => sum + g.accuracy) / totalGames;

    return {
      'generation': generationNumber,
      'totalGames': totalGames,
      'wins': wins,
      'winRate': (wins / totalGames * 100).toStringAsFixed(1),
      'avgAccuracy': avgAccuracy.toStringAsFixed(1),
      'bestWinRate': (bestWinRate * 100).toStringAsFixed(1),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
