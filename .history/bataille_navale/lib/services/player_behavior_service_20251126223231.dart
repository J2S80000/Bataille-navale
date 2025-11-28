import 'dart:math';
import '../models/index.dart';
import '../ai/genetic_algorithm.dart';

/// Service d'analyse du comportement des joueurs pour adapter l'IA
class PlayerBehaviorService {
  /// Analyse les patterns de placement de navires du joueur
  /// Détecte où le joueur a tendance à placer ses navires
  static Map<String, dynamic> analyzeShipPlacementPatterns(
    List<GameStatistics> playerGames,
  ) {
    if (playerGames.isEmpty) {
      return {
        'centerPreference': 0.0,
        'cornerPreference': 0.0,
        'edgePreference': 0.0,
        'horizontalBias': 0.5,
        'predictedHeatmap': List<int>.filled(100, 0),
      };
    }

    // Analyser les positions des coups ennemis (où l'IA a tiré)
    // et reconstruire les emplacements probables des navires
    final allHitPositions = <(int, int)>[];
    final allMissPositions = <(int, int)>[];

    for (final game in playerGames) {
      allHitPositions.addAll(game.hitPositions);
      allMissPositions.addAll(game.missPositions);
    }

    // Créer une heatmap de concentration des coups
    final heatmap = List<int>.filled(100, 0);
    for (final (row, col) in allHitPositions) {
      heatmap[row * 10 + col] += 2; // Poids +2 pour les touches
    }
    for (final (row, col) in allMissPositions) {
      heatmap[row * 10 + col] += 1; // Poids +1 pour les manqués
    }

    // Calculer les préférences de zone
    double centerCount = 0;
    double cornerCount = 0;
    double edgeCount = 0;

    for (int i = 0; i < 100; i++) {
      final row = i ~/ 10;
      final col = i % 10;
      final value = heatmap[i].toDouble();

      if ((row >= 3 && row <= 6) && (col >= 3 && col <= 6)) {
        centerCount += value;
      } else if ((row == 0 || row == 9) && (col == 0 || col == 9)) {
        cornerCount += value;
      } else if (row == 0 || row == 9 || col == 0 || col == 9) {
        edgeCount += value;
      }
    }

    final total = centerCount + cornerCount + edgeCount + 0.0001; // Éviter division par 0
    final centerPref = centerCount / total;
    final cornerPref = cornerCount / total;
    final edgePref = edgeCount / total;

    // Analyser tendance horizontale vs verticale
    double horizontalHits = 0;
    double verticalHits = 0;

    for (int i = 0; i < allHitPositions.length - 1; i++) {
      final current = allHitPositions[i];
      final next = allHitPositions[i + 1];

      if (current.$1 == next.$1) {
        // Même ligne = horizontal
        horizontalHits++;
      } else if (current.$2 == next.$2) {
        // Même colonne = vertical
        verticalHits++;
      }
    }

    final horizontalBias =
        (horizontalHits / (horizontalHits + verticalHits + 0.0001)).clamp(0.0, 1.0);

    return {
      'centerPreference': centerPref,
      'cornerPreference': cornerPref,
      'edgePreference': edgePref,
      'horizontalBias': horizontalBias,
      'predictedHeatmap': heatmap,
      'totalGamesAnalyzed': playerGames.length,
      'patternConfidence':
          ((allHitPositions.length / (allHitPositions.length + allMissPositions.length)) *
              100),
    };
  }

  /// Analyse les patterns d'attaque du joueur
  /// Détecte la stratégie: aléatoire, linéaire, systématique, clustering, etc.
  static Map<String, dynamic> analyzeAttackPatterns(List<GameStatistics> playerGames) {
    if (playerGames.isEmpty) {
      return {
        'strategy': 'unknown',
        'attackClusterSize': 0.0,
        'moveSequentialityScore': 0.0,
        'predictability': 0.0,
      };
    }

    // Analyser les attaques du joueur
    final allAttacks = <(int, int)>[];
    for (final game in playerGames) {
      allAttacks.addAll(game.hitPositions);
      allAttacks.addAll(game.missPositions);
    }

    if (allAttacks.length < 2) {
      return {
        'strategy': 'too_few_games',
        'attackClusterSize': 0.0,
        'moveSequentialityScore': 0.0,
        'predictability': 0.0,
      };
    }

    // Calculer le clustering: les attaques sont-elles groupées?
    double clusterScore = 0;
    for (int i = 0; i < allAttacks.length - 1; i++) {
      final curr = allAttacks[i];
      final next = allAttacks[i + 1];
      final distance = sqrt(pow(curr.$1 - next.$1, 2) + pow(curr.$2 - next.$2, 2));
      if (distance <= 3) {
        clusterScore++;
      }
    }
    final clusterRatio = clusterScore / (allAttacks.length - 1);

    // Score de séquentialité: les attaques suivent-elles un ordre linéaire?
    double sequentialScore = 0;
    for (int i = 0; i < allAttacks.length - 2; i++) {
      final p1 = allAttacks[i];
      final p2 = allAttacks[i + 1];
      final p3 = allAttacks[i + 2];

      // Vérifier si les 3 points sont alignés (même ligne ou colonne)
      if ((p1.$1 == p2.$1 && p2.$1 == p3.$1) || (p1.$2 == p2.$2 && p2.$2 == p3.$2)) {
        sequentialScore++;
      }
    }
    final sequentialRatio = sequentialScore / max(1, (allAttacks.length - 2));

    // Déterminer la stratégie
    String strategy = 'random';
    if (clusterRatio > 0.7) {
      strategy = 'clustering'; // L'IA doit se concentrer sur les zones d'attaque
    } else if (sequentialRatio > 0.6) {
      strategy = 'linear'; // L'IA doit scanner ligne par ligne
    } else if (clusterRatio > 0.5) {
      strategy = 'semi-systematic'; // Partiellement organisé
    }

    final predictability = ((clusterRatio + sequentialRatio) / 2 * 100).clamp(0, 100);

    return {
      'strategy': strategy,
      'attackClusterSize': clusterRatio,
      'moveSequentialityScore': sequentialRatio,
      'predictability': predictability,
      'totalAttacks': allAttacks.length,
    };
  }

  /// Génère une stratégie d'IA adaptée au comportement du joueur
  static AIStrategy generateAdaptiveStrategy({
    required Map<String, dynamic> placementPatterns,
    required Map<String, dynamic> attackPatterns,
    required String strategyId,
  }) {
    final centerPref = (placementPatterns['centerPreference'] as num).toDouble();
    final cornerPref = (placementPatterns['cornerPreference'] as num).toDouble();
    final edgePref = (placementPatterns['edgePreference'] as num).toDouble();
    final horizontalBias = (placementPatterns['horizontalBias'] as num).toDouble();

    final playerStrategy = attackPatterns['strategy'] as String;
    final clusterSize = (attackPatterns['attackClusterSize'] as num).toDouble();

    // Weights: [proximité, densité, espacement, hotspots, exploration]
    var weights = [0.2, 0.2, 0.2, 0.2, 0.2]; // Neutre par défaut

    // Adapter selon les préférences de placement du joueur
    if (centerPref > 0.4) {
      // Le joueur place au centre → augmenter proximité et densité au centre
      weights[0] += 0.2; // proximité
      weights[1] += 0.1; // densité
    }

    if (cornerPref > 0.3) {
      // Le joueur place aux coins → adapter les hotspots
      weights[3] += 0.25; // hotspots
    }

    if (edgePref > 0.3) {
      // Le joueur place aux bords
      weights[4] += 0.15; // exploration des bords
    }

    // Adapter selon la stratégie d'attaque du joueur
    switch (playerStrategy) {
      case 'clustering':
        // Le joueur attaque par clusters → dépenser moins en exploration
        weights[4] = (weights[4] - 0.15).clamp(0.0, 1.0);
        weights[1] += 0.2; // densité
        break;
      case 'linear':
        // Le joueur attaque de façon systématique → aussi systématique
        weights[1] += 0.25; // densité forte
        break;
      case 'semi-systematic':
        // Équilibre
        weights[1] += 0.15;
        weights[4] += 0.1;
        break;
      default:
        // Aléatoire → exploration élevée
        weights[4] += 0.2;
        break;
    }

    // Normaliser les weights
    final sum = weights.reduce((a, b) => a + b);
    weights = weights.map((w) => w / sum).toList();

    return AIStrategy(
      id: strategyId,
      weights: weights,
    );
  }

  /// Identifie les zones "dangereuses" où l'IA devrait attaquer en priorité
  static List<(int, int)> identifyHighRiskZones(
    Map<String, dynamic> patterns,
    int topZones = 5,
  ) {
    final heatmap = (patterns['predictedHeatmap'] as List).cast<int>();
    final highRiskZones = <(int, int, int)>[];

    for (int i = 0; i < 100; i++) {
      final row = i ~/ 10;
      final col = i % 10;
      final value = heatmap[i];

      if (value > 0) {
        highRiskZones.add((row, col, value));
      }
    }

    // Trier par valeur décroissante
    highRiskZones.sort((a, b) => b.$3.compareTo(a.$3));

    // Retourner les top zones
    return highRiskZones.take(topZones).map((z) => (z.$1, z.$2)).toList();
  }

  /// Génère un rapport complet d'analyse comportementale
  static Map<String, dynamic> generateBehaviorReport(
    String playerId,
    List<GameStatistics> playerGames,
  ) {
    final placementPatterns = analyzeShipPlacementPatterns(playerGames);
    final attackPatterns = analyzeAttackPatterns(playerGames);

    return {
      'playerId': playerId,
      'analysisDate': DateTime.now().toIso8601String(),
      'gamesAnalyzed': playerGames.length,
      'placementPatterns': placementPatterns,
      'attackPatterns': attackPatterns,
      'highRiskZones': identifyHighRiskZones(placementPatterns),
    };
  }
}
