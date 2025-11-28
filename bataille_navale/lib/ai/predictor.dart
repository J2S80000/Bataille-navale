import 'dart:math';
import '../models/index.dart';
import 'genetic_algorithm.dart';

/// Prédicteur de coups pour l'IA
class MovePredictor {
  final AIStrategy strategy;
  final List<GameStatistics> trainingData;
  final Random _random = Random();

  MovePredictor({
    required this.strategy,
    required this.trainingData,
  });

  /// Prédit le prochain coup optimal
  (int row, int col) predictNextMove(
    Board opponentBoard,
    List<Move> gameHistory,
  ) {
    // Collecter les positions possibles
    final possibleMoves = <(int, int)>[];

    for (int row = 0; row < 10; row++) {
      for (int col = 0; col < 10; col++) {
        final cell = opponentBoard.getCell(row, col);
        if (cell.state == CellState.empty) {
          possibleMoves.add((row, col));
        }
      }
    }

    if (possibleMoves.isEmpty) {
      throw StateError('Aucun coup possible');
    }

    // Évaluer chaque position
    final scores = <(int, int, double)>[];

    for (final pos in possibleMoves) {
      final score = _evaluatePosition(
        pos,
        opponentBoard,
        gameHistory,
      );
      scores.add((pos.$1, pos.$2, score));
    }

    // Retourner le meilleur coup
    scores.sort((a, b) => b.$3.compareTo(a.$3));
    final bestMove = scores.first;

    return (bestMove.$1, bestMove.$2);
  }

  /// Évalue une position basée sur plusieurs heuristiques
  double _evaluatePosition(
    (int, int) position,
    Board opponentBoard,
    List<Move> gameHistory,
  ) {
    double score = 0.0;

    // Heuristique 1: Proximité avec les coups touchés
    score += strategy.weights[0] * _proximityToHits(position, gameHistory);

    // Heuristique 2: Densité de navires dans la zone
    score += strategy.weights[1] * _shipDensity(position, trainingData);

    // Heuristique 3: Espacement (éviter les coups trop proches)
    score += strategy.weights[2] * _spacingScore(position, gameHistory);

    // Heuristique 4: Zones chaudes (basées sur les patterns d'adversaires)
    score += strategy.weights[3] * _hotspotScore(position);

    // Heuristique 5: Exploration (ne pas rester trop localisé)
    score += strategy.weights[4] * _explorationScore(position, gameHistory);

    // Ajouter du bruit pour de la variabilité
    score += (_random.nextDouble() - 0.5) * 0.05;

    return score;
  }

  /// Score de proximité aux coups touchés (pour continuer à explorer)
  double _proximityToHits(
    (int, int) position,
    List<Move> gameHistory,
  ) {
    final recentHits =
        gameHistory.where((m) => m.result == MoveResult.hit).toList();

    if (recentHits.isEmpty) return 0.0;

    double closestDistance = 10.0;

    for (final hit in recentHits) {
      final distance = ((position.$1 - hit.row).abs() +
              (position.$2 - hit.col).abs())
          .toDouble();
      closestDistance = min(closestDistance, distance);
    }

    // Préférer les positions proches des hits (distance 1-2)
    if (closestDistance <= 2) return 1.0;
    if (closestDistance <= 4) return 0.5;
    return 0.1;
  }

  /// Densité de navires estimée dans la zone
  double _shipDensity(
    (int, int) position,
    List<GameStatistics> trainingData,
  ) {
    if (trainingData.isEmpty) return 0.5;

    // Utiliser la heatmap agrégée
    int hitCount = 0;
    for (final stat in trainingData) {
      for (final hit in stat.hitPositions) {
        if ((hit.$1 - position.$1).abs() <= 2 &&
            (hit.$2 - position.$2).abs() <= 2) {
          hitCount++;
        }
      }
    }

    return (hitCount / (trainingData.length * 5)).clamp(0.0, 1.0);
  }

  /// Score d'espacement (préférer les coups espacés)
  double _spacingScore(
    (int, int) position,
    List<Move> gameHistory,
  ) {
    if (gameHistory.isEmpty) return 1.0;

    final lastMoves = gameHistory.take(10).toList();
    double minDistance = 10.0;

    for (final move in lastMoves) {
      final distance =
          sqrt(pow(position.$1 - move.row, 2) + pow(position.$2 - move.col, 2))
              .toDouble();
      minDistance = min(minDistance, distance);
    }

    // Préférer les positions espacées
    return (minDistance / 10).clamp(0.0, 1.0);
  }

  /// Score basé sur les hotspots
  double _hotspotScore((int, int) position) {
    // Les coins et les bords sont généralement privilégiés
    final row = position.$1;
    final col = position.$2;

    // Zone chaude centrale (4-6)
    if (row >= 3 && row <= 6 && col >= 3 && col <= 6) {
      return 0.8;
    }

    // Bords
    if (row <= 2 || row >= 7 || col <= 2 || col >= 7) {
      return 0.6;
    }

    return 0.4;
  }

  /// Score d'exploration (couvrir différentes zones)
  double _explorationScore(
    (int, int) position,
    List<Move> gameHistory,
  ) {
    if (gameHistory.isEmpty) return 1.0;

    // Compter les coups dans chaque quadrant
    int quadrantCount = 0;
    final quadrant = (position.$1 ~/ 5, position.$2 ~/ 5);

    for (final move in gameHistory) {
      final moveQuadrant = (move.row ~/ 5, move.col ~/ 5);
      if (moveQuadrant == quadrant) {
        quadrantCount++;
      }
    }

    // Préférer les zones peu explorées
    return 1.0 / (1.0 + (quadrantCount / 5));
  }

  /// Factory pour créer un prédicteur depuis une stratégie sauvegardée
  factory MovePredictor.fromSavedStrategy(
    Map<String, dynamic> strategyJson,
    List<GameStatistics> trainingData,
  ) {
    final strategy = AIStrategy.fromJson(strategyJson);
    return MovePredictor(
      strategy: strategy,
      trainingData: trainingData,
    );
  }
}
