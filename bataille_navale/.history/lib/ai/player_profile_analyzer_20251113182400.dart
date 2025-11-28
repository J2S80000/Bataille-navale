import 'dart:math';
import '../models/index.dart';

/// Analyse les patterns de jeu des joueurs
class PlayerProfileAnalyzer {
  /// Identifie les zones "chaudes" (les plus souvent ciblées)
  static List<List<double>> analyzeHotZones(List<GameStatistics> games) {
    final heatmap = List.generate(10, (_) => List.generate(10, (_) => 0.0));

    for (final game in games) {
      // Analyser les coups gagnants
      for (final (row, col) in game.hitPositions) {
        if (row >= 0 && row < 10 && col >= 0 && col < 10) {
          heatmap[row][col] += 1.0;
        }
      }
    }

    // Normaliser la heatmap
    double maxValue = 0;
    for (final row in heatmap) {
      for (final value in row) {
        if (value > maxValue) maxValue = value;
      }
    }

    if (maxValue > 0) {
      for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 10; j++) {
          heatmap[i][j] /= maxValue;
        }
      }
    }

    return heatmap;
  }

  /// Calcule la distribution des coups (pattern d'attaque)
  static Map<String, dynamic> analyzeAttackPattern(List<GameStatistics> games) {
    int aggressiveShots = 0; // Coups en séquence rapide
    int defensiveShots = 0; // Coups espacés
    int randomShots = 0;
    double averageAccuracy = 0;

    for (final game in games) {
      final totalShots = game.totalMoves;
      final hits = game.hits;

      if (game.accuracy > 50) {
        aggressiveShots += totalShots;
      } else if (game.accuracy < 25) {
        defensiveShots += totalShots;
      } else {
        randomShots += totalShots;
      }

      averageAccuracy += game.accuracy;
    }

    if (games.isNotEmpty) {
      averageAccuracy /= games.length;
    }

    return {
      'aggressive': aggressiveShots / max(1, games.length),
      'defensive': defensiveShots / max(1, games.length),
      'random': randomShots / max(1, games.length),
      'averageAccuracy': averageAccuracy,
      'style': _classifyPlayStyle(
        aggressiveShots,
        defensiveShots,
        randomShots,
      ),
    };
  }

  /// Identifie le style de jeu
  static String _classifyPlayStyle(
    int aggressive,
    int defensive,
    int random,
  ) {
    if (aggressive > defensive && aggressive > random) {
      return 'aggressive';
    } else if (defensive > aggressive && defensive > random) {
      return 'defensive';
    } else if (random > aggressive && random > defensive) {
      return 'random';
    }
    return 'balanced';
  }

  /// Calcule la distribution des navires (où l'adversaire les place souvent)
  static List<List<double>> predictShipPlacement(
    List<GameStatistics> games,
  ) {
    final predictions = List.generate(10, (_) => List.generate(10, (_) => 0.0));

    // Analyser les zones où les navires ont été touchés
    for (final game in games) {
      for (final (row, col) in game.hitPositions) {
        // Augmenter les prédictions autour des hits
        for (int i = max(0, row - 1); i <= min(9, row + 1); i++) {
          for (int j = max(0, col - 1); j <= min(9, col + 1); j++) {
            predictions[i][j] += 0.5;
          }
        }
      }
    }

    // Normaliser
    double maxValue = 0;
    for (final row in predictions) {
      for (final value in row) {
        if (value > maxValue) maxValue = value;
      }
    }

    if (maxValue > 0) {
      for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 10; j++) {
          predictions[i][j] /= maxValue;
        }
      }
    }

    return predictions;
  }

  /// Identifie les zones "froides" (rarement ciblées)
  static List<List<double>> analyzeColdZones(List<GameStatistics> games) {
    final coldmap = List.generate(10, (_) => List.generate(10, (_) => 1.0));
    final heatmap = analyzeHotZones(games);

    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 10; j++) {
        coldmap[i][j] = 1.0 - heatmap[i][j];
      }
    }

    return coldmap;
  }

  /// Estime la compétence du joueur
  static double calculateSkillRating(List<GameStatistics> games) {
    if (games.isEmpty) return 0.5; // Rating par défaut

    double totalAccuracy = 0;
    int totalWins = 0;

    for (final game in games) {
      totalAccuracy += game.accuracy;
      if (game.won) totalWins++;
    }

    final averageAccuracy = totalAccuracy / games.length;
    final winRate = totalWins / games.length;

    // Formule: (accuracy * 0.6 + winRate * 0.4) / 100
    return ((averageAccuracy * 0.6 + (winRate * 100) * 0.4) / 100);
  }

  /// Analyse la progressivité du joueur
  static Map<String, dynamic> analyzeProgression(List<GameStatistics> games) {
    if (games.length < 2) {
      return {
        'trend': 'insufficient_data',
        'earlyAccuracy': 0.0,
        'lateAccuracy': 0.0,
        'improvement': 0.0,
      };
    }

    final midpoint = games.length ~/ 2;
    final earlyGames = games.sublist(0, midpoint);
    final lateGames = games.sublist(midpoint);

    double earlyAccuracy = 0;
    double lateAccuracy = 0;

    for (final game in earlyGames) {
      earlyAccuracy += game.accuracy;
    }
    earlyAccuracy /= earlyGames.length;

    for (final game in lateGames) {
      lateAccuracy += game.accuracy;
    }
    lateAccuracy /= lateGames.length;

    final improvement = lateAccuracy - earlyAccuracy;
    final trend = improvement > 5
        ? 'improving'
        : improvement < -5
            ? 'declining'
            : 'stable';

    return {
      'trend': trend,
      'earlyAccuracy': earlyAccuracy,
      'lateAccuracy': lateAccuracy,
      'improvement': improvement,
    };
  }
}
