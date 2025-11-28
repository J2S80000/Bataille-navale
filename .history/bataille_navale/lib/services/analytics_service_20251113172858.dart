import '../models/index.dart';

class AnalyticsService {
  const AnalyticsService();

  /// Construit et retourne les stats agrégées complètes
  Future<PlayerStatisticsAggregate> buildPlayerStatistics(
    String playerId,
    List<GameStatistics> allGameStats,
  ) async {
    final totalGames = allGameStats.length;
    final totalWins = allGameStats.where((s) => s.won).length;
    final totalLosses = totalGames - totalWins;

    final winRate = totalGames > 0 ? totalWins / totalGames : 0.0;

    final totalHits = allGameStats.fold<int>(0, (sum, s) => sum + s.hits);
    final totalMisses = allGameStats.fold<int>(0, (sum, s) => sum + s.misses);

    final averageAccuracy = allGameStats.isEmpty
        ? 0.0
        : allGameStats.fold<double>(0.0, (sum, s) => sum + s.accuracy) /
            allGameStats.length;

    // Génère la heatmap
    final heatmap = _generateHeatmap(allGameStats);

    // Analyse les timings
    final moveTiming = _analyzeMoveTimings(allGameStats);

    return PlayerStatisticsAggregate(
      playerId: playerId,
      totalGames: totalGames,
      totalWins: totalWins,
      totalLosses: totalLosses,
      winRate: winRate,
      averageAccuracy: averageAccuracy,
      totalHits: totalHits,
      totalMisses: totalMisses,
      heatmap: heatmap,
      moveTiming: moveTiming,
    );
  }

  /// Génère une heatmap 10x10 des positions les plus attaquées
  List<int> _generateHeatmap(List<GameStatistics> gameStats) {
    final heatmap = List<int>.filled(100, 0);

    for (final stat in gameStats) {
      for (final pos in stat.hitPositions) {
        final index = pos.$1 * 10 + pos.$2;
        if (index >= 0 && index < 100) {
          heatmap[index]++;
        }
      }
    }

    return heatmap;
  }

  /// Analyse les timings de coups (timing moyen entre chaque coup)
  Map<String, int> _analyzeMoveTimings(List<GameStatistics> gameStats) {
    final timings = <String, int>{};
    int fastMoves = 0; // < 5 sec
    int normalMoves = 0; // 5-15 sec
    int slowMoves = 0; // > 15 sec

    for (final stat in gameStats) {
      if (stat.totalMoves > 0) {
        final avgTime = stat.gameDuration.inSeconds ~/ stat.totalMoves;

        if (avgTime < 5) {
          fastMoves++;
        } else if (avgTime < 15) {
          normalMoves++;
        } else {
          slowMoves++;
        }
      }
    }

    timings['fast_moves'] = fastMoves;
    timings['normal_moves'] = normalMoves;
    timings['slow_moves'] = slowMoves;

    return timings;
  }

  /// Retourne les zones les plus chaudes du plateau
  List<(int, int, int)> getHotspots(List<int> heatmap, {int top = 5}) {
    final spots = <(int, int, int)>[];

    for (int i = 0; i < heatmap.length; i++) {
      final row = i ~/ 10;
      final col = i % 10;
      spots.add((row, col, heatmap[i]));
    }

    spots.sort((a, b) => b.$3.compareTo(a.$3));
    return spots.take(top).toList();
  }

  /// Calcule le coefficient d'adaptation (pour l'IA)
  double calculateAdaptationCoefficient(
    List<GameStatistics> gameStats,
    int recentGames,
  ) {
    if (gameStats.isEmpty) return 0.5;

    final recent = gameStats.take(recentGames).toList();
    final recentWins = recent.where((s) => s.won).length;
    final recentWinRate = recentWins / recent.length;

    // Bonus si haute précision
    final avgAccuracy =
        recent.fold<double>(0, (sum, s) => sum + s.accuracy) / recent.length;

    return (recentWinRate * 0.7) + (avgAccuracy / 100 * 0.3);
  }

  /// Détecte les patterns de coups (clustering)
  Map<String, List<(int, int)>> detectMovePatterns(
    List<GameStatistics> gameStats,
  ) {
    final patterns = <String, List<(int, int)>>{};

    for (final stat in gameStats) {
      // Détecte les attaques linéaires
      _detectLinearPatterns(stat.hitPositions, patterns);

      // Détecte les attaques en croix
      _detectCrossPatterns(stat.hitPositions, patterns);

      // Détecte les attaques aléatoires
      _detectRandomPatterns(stat.hitPositions, patterns);
    }

    return patterns;
  }

  void _detectLinearPatterns(
    List<(int, int)> positions,
    Map<String, List<(int, int)>> patterns,
  ) {
    // Détecte les coups en ligne horizontale/verticale
    for (int i = 0; i < positions.length - 1; i++) {
      final current = positions[i];
      final next = positions[i + 1];

      if (current.$1 == next.$1) {
        // Même ligne
        patterns.putIfAbsent('horizontal_attacks', () => []);
        patterns['horizontal_attacks']!.add(current);
      } else if (current.$2 == next.$2) {
        // Même colonne
        patterns.putIfAbsent('vertical_attacks', () => []);
        patterns['vertical_attacks']!.add(current);
      }
    }
  }

  void _detectCrossPatterns(
    List<(int, int)> positions,
    Map<String, List<(int, int)>> patterns,
  ) {
    // Détecte les attaques en croix (diagonales)
    for (int i = 0; i < positions.length - 1; i++) {
      final current = positions[i];
      final next = positions[i + 1];

      if ((current.$1 - next.$1).abs() == 1 &&
          (current.$2 - next.$2).abs() == 1) {
        patterns.putIfAbsent('cross_attacks', () => []);
        patterns['cross_attacks']!.add(current);
      }
    }
  }

  void _detectRandomPatterns(
    List<(int, int)> positions,
    Map<String, List<(int, int)>> patterns,
  ) {
    // Tout ce qui n'est pas linéaire ou en croix est considéré comme aléatoire
    if (positions.length > 2) {
      patterns.putIfAbsent('random_attacks', () => []);
      patterns['random_attacks']!.addAll(positions);
    }
  }

  /// Génère un score de prédictibilité (0 = imprévisible, 1 = très prévisible)
  double calculatePredictability(List<GameStatistics> gameStats) {
    if (gameStats.isEmpty) return 0.0;

    double score = 0.0;
    int count = 0;

    for (final stat in gameStats) {
      // Coups concentrés dans une zone = plus prévisible
      final avgRow =
          stat.hitPositions.isEmpty ? 0 : stat.hitPositions.map((p) => p.$1).reduce((a, b) => a + b) / stat.hitPositions.length;
      final avgCol =
          stat.hitPositions.isEmpty ? 0 : stat.hitPositions.map((p) => p.$2).reduce((a, b) => a + b) / stat.hitPositions.length;

      double variance = 0;
      for (final pos in stat.hitPositions) {
        variance += (pos.$1 - avgRow).abs() + (pos.$2 - avgCol).abs();
      }

      final normalizedVariance = stat.hitPositions.isEmpty ? 0 : variance / stat.hitPositions.length;
      score += (18 - normalizedVariance) / 18; // Normaliser à 0-1

      count++;
    }

    return count > 0 ? score / count : 0.0;
  }
}
