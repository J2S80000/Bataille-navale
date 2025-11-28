import 'dart:math';
import '../models/index.dart';

/// Représente une stratégie d'IA
class AIStrategy {
  final List<double> weights; // Poids pour différentes heuristiques
  final String id;
  double fitness;

  AIStrategy({
    required this.weights,
    required this.id,
    this.fitness = 0.0,
  }) : assert(weights.length == 5, 'Une stratégie doit avoir 5 poids');

  /// Crée une copie avec mutation
  AIStrategy mutate(Random random) {
    final newWeights = weights.map((w) {
      // 10% de chance de mutation
      if (random.nextDouble() < 0.1) {
        return (w + (random.nextDouble() - 0.5) * 0.2).clamp(0.0, 1.0);
      }
      return w;
    }).toList();

    return AIStrategy(
      weights: newWeights,
      id: '${id}_mutated',
      fitness: 0.0,
    );
  }

  /// Croise deux stratégies
  static AIStrategy crossover(AIStrategy parent1, AIStrategy parent2, Random random) {
    final newWeights = <double>[];

    for (int i = 0; i < parent1.weights.length; i++) {
      if (random.nextBool()) {
        newWeights.add(parent1.weights[i]);
      } else {
        newWeights.add(parent2.weights[i]);
      }
    }

    return AIStrategy(
      weights: newWeights,
      id: '${parent1.id}_x_${parent2.id}',
      fitness: 0.0,
    );
  }

  /// Génère une stratégie aléatoire
  factory AIStrategy.random(Random random) {
    return AIStrategy(
      weights: List.generate(5, (_) => random.nextDouble()),
      id: 'random_${random.nextInt(10000)}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weights': weights,
      'fitness': fitness,
    };
  }

  factory AIStrategy.fromJson(Map<String, dynamic> json) {
    return AIStrategy(
      id: json['id'] as String,
      weights: List<double>.from(json['weights'] as List),
      fitness: json['fitness'] as double? ?? 0.0,
    );
  }
}

/// Algorithme génétique pour l'entraînement d'IA
class GeneticAlgorithm {
  final int populationSize;
  final int generations;
  final double mutationRate;
  final double crossoverRate;
  final Random _random = Random();

  List<AIStrategy> population = [];
  List<AIStrategy> history = [];

  GeneticAlgorithm({
    this.populationSize = 20,
    this.generations = 50,
    this.mutationRate = 0.1,
    this.crossoverRate = 0.7,
  });

  /// Initialise la population
  void initializePopulation() {
    population = List.generate(
      populationSize,
      (_) => AIStrategy.random(_random),
    );
  }

  /// Évalue la fitness basée sur l'historique de jeu
  void evaluateFitness(List<GameStatistics> gameStats) {
    for (final strategy in population) {
      strategy.fitness = _calculateFitness(strategy, gameStats);
    }

    // Trier par fitness décroissante
    population.sort((a, b) => b.fitness.compareTo(a.fitness));
  }

  double _calculateFitness(AIStrategy strategy, List<GameStatistics> gameStats) {
    double score = 0.0;

    for (final stat in gameStats) {
      // w0: Win rate (0.0-1.0)
      score += strategy.weights[0] * (stat.won ? 1.0 : 0.0);

      // w1: Accuracy (normalisée 0-1)
      score += strategy.weights[1] * (stat.accuracy / 100);

      // w2: Ships destroyed
      score += strategy.weights[2] * (stat.shipsDestroyed / 5);

      // w3: Move efficiency (moins de coups pour gagner)
      score += strategy.weights[3] * (1.0 / (1.0 + (stat.totalMoves / 50)));

      // w4: Concentration de coups (variance faible = bon)
      final concentration = _calculateConcentration(stat.hitPositions);
      score += strategy.weights[4] * concentration;
    }

    return score / (gameStats.isEmpty ? 1 : gameStats.length);
  }

  double _calculateConcentration(List<(int, int)> positions) {
    if (positions.isEmpty) return 0.0;

    double avgRow = positions.map((p) => p.$1).reduce((a, b) => a + b) / positions.length;
    double avgCol = positions.map((p) => p.$2).reduce((a, b) => a + b) / positions.length;

    double variance = 0;
    for (final pos in positions) {
      variance += pow(pos.$1 - avgRow, 2).toDouble() +
          pow(pos.$2 - avgCol, 2).toDouble();
    }

    variance /= positions.length;
    return 1.0 / (1.0 + (variance / 50)); // Normaliser
  }

  /// Effectue une génération de l'algorithme génétique
  void evolveGeneration() {
    final newPopulation = <AIStrategy>[];

    // Élitisme: garder les 2 meilleurs
    newPopulation.addAll(population.take(2));

    // Générer le reste par crossover et mutation
    while (newPopulation.length < populationSize) {
      AIStrategy parent1 = _selectByTournament();
      AIStrategy parent2 = _selectByTournament();

      AIStrategy child = AIStrategy.crossover(parent1, parent2, _random);

      if (_random.nextDouble() < mutationRate) {
        child = child.mutate(_random);
      }

      newPopulation.add(child);
    }

    population = newPopulation;
  }

  /// Sélection par tournoi
  AIStrategy _selectByTournament({int tournamentSize = 3}) {
    final tournament = <AIStrategy>[];
    for (int i = 0; i < tournamentSize; i++) {
      tournament.add(population[_random.nextInt(population.length)]);
    }
    tournament.sort((a, b) => b.fitness.compareTo(a.fitness));
    return tournament.first;
  }

  /// Lance l'entraînement complet
  void train(List<GameStatistics> gameStats) {
    initializePopulation();

    for (int gen = 0; gen < generations; gen++) {
      evaluateFitness(gameStats);
      history.add(AIStrategy.fromJson(population.first.toJson()));

      if (gen < generations - 1) {
        evolveGeneration();
      }
    }
  }

  /// Obtient la meilleure stratégie trouvée
  AIStrategy getBestStrategy() {
    return population.isNotEmpty ? population.first : AIStrategy.random(_random);
  }

  /// Obtient l'historique de fitness
  List<double> getFitnessHistory() {
    return history.map((s) => s.fitness).toList();
  }
}
