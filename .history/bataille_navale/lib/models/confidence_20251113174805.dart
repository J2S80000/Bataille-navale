import 'package:equatable/equatable.dart';

/// Intervalle de confiance pour un coup (statistiques bayesiennes)
class ConfidenceInterval extends Equatable {
  final double probability;        // Probabilité d'avoir un navire (0-1)
  final double lowerBound;         // Limite inférieure (95%)
  final double upperBound;         // Limite supérieure (95%)
  final int sampleSize;            // Nombre de parties analysées
  final String riskLevel;          // "low", "medium", "high"

  const ConfidenceInterval({
    required this.probability,
    required this.lowerBound,
    required this.upperBound,
    required this.sampleSize,
    required this.riskLevel,
  });

  /// Calcule le risque associé (5% = risque normalement acceptable)
  double get risk => 1.0 - probability;
  
  bool get isLowRisk => riskLevel == 'low';
  bool get isMediumRisk => riskLevel == 'medium';
  bool get isHighRisk => riskLevel == 'high';

  Map<String, dynamic> toJson() {
    return {
      'probability': probability,
      'lowerBound': lowerBound,
      'upperBound': upperBound,
      'sampleSize': sampleSize,
      'riskLevel': riskLevel,
    };
  }

  factory ConfidenceInterval.fromJson(Map<String, dynamic> json) {
    return ConfidenceInterval(
      probability: json['probability'] as double,
      lowerBound: json['lowerBound'] as double,
      upperBound: json['upperBound'] as double,
      sampleSize: json['sampleSize'] as int,
      riskLevel: json['riskLevel'] as String,
    );
  }

  @override
  List<Object?> get props => [probability, lowerBound, upperBound, sampleSize, riskLevel];
}

/// Heatmap avec intervalles de confiance
class ConfidenceHeatmap extends Equatable {
  final List<ConfidenceInterval> grid; // 100 cellules (10x10)
  final DateTime calculatedAt;
  final int totalAnalyzedGames;

  const ConfidenceHeatmap({
    required this.grid,
    required this.calculatedAt,
    required this.totalAnalyzedGames,
  }) : assert(grid.length == 100, 'Heatmap doit avoir 100 cellules');

  /// Obtient l'intervalle pour une position
  ConfidenceInterval getCell(int row, int col) {
    if (row < 0 || row >= 10 || col < 0 || col >= 10) {
      throw ArgumentError('Position invalide');
    }
    return grid[row * 10 + col];
  }

  /// Top N positions avec meilleure probabilité
  List<(int row, int col, double prob)> getTopPositions({int limit = 10}) {
    final positions = <(int, int, double)>[];

    for (int i = 0; i < grid.length; i++) {
      final row = i ~/ 10;
      final col = i % 10;
      positions.add((row, col, grid[i].probability));
    }

    positions.sort((a, b) => b.$3.compareTo(a.$3));
    return positions.take(limit).toList();
  }

  /// Positions acceptables (risque <= 5%)
  List<(int row, int col)> getAcceptablePositions({double riskThreshold = 0.05}) {
    final acceptable = <(int, int)>[];

    for (int i = 0; i < grid.length; i++) {
      if (grid[i].risk <= riskThreshold) {
        acceptable.add((i ~/ 10, i % 10));
      }
    }

    return acceptable;
  }

  Map<String, dynamic> toJson() {
    return {
      'grid': grid.map((ci) => ci.toJson()).toList(),
      'calculatedAt': calculatedAt.toIso8601String(),
      'totalAnalyzedGames': totalAnalyzedGames,
    };
  }

  factory ConfidenceHeatmap.fromJson(Map<String, dynamic> json) {
    return ConfidenceHeatmap(
      grid: (json['grid'] as List)
          .map((item) => ConfidenceInterval.fromJson(item as Map<String, dynamic>))
          .toList(),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      totalAnalyzedGames: json['totalAnalyzedGames'] as int,
    );
  }

  @override
  List<Object?> get props => [grid, calculatedAt, totalAnalyzedGames];
}

/// Stratégie de placement initial basée sur l'analyse
class InitialPlacementStrategy extends Equatable {
  final List<(int row, int col, bool vertical)> recommendedPositions;
  final String strategyName; // "aggressive", "defensive", "balanced"
  final ConfidenceHeatmap confidenceHeatmap;
  final double expectedWinRate;

  const InitialPlacementStrategy({
    required this.recommendedPositions,
    required this.strategyName,
    required this.confidenceHeatmap,
    required this.expectedWinRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'recommendedPositions': recommendedPositions
          .map((p) => {'row': p.$1, 'col': p.$2, 'vertical': p.$3})
          .toList(),
      'strategyName': strategyName,
      'confidenceHeatmap': confidenceHeatmap.toJson(),
      'expectedWinRate': expectedWinRate,
    };
  }

  factory InitialPlacementStrategy.fromJson(Map<String, dynamic> json) {
    return InitialPlacementStrategy(
      recommendedPositions: (json['recommendedPositions'] as List)
          .map((p) => (p['row'] as int, p['col'] as int, p['vertical'] as bool))
          .toList(),
      strategyName: json['strategyName'] as String,
      confidenceHeatmap:
          ConfidenceHeatmap.fromJson(json['confidenceHeatmap'] as Map<String, dynamic>),
      expectedWinRate: json['expectedWinRate'] as double,
    );
  }

  @override
  List<Object?> get props =>
      [recommendedPositions, strategyName, confidenceHeatmap, expectedWinRate];
}
