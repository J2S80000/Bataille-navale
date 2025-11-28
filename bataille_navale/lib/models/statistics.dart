import 'package:equatable/equatable.dart';

class GameStatistics extends Equatable {
  final String gameId;
  final String playerId;
  final String opponentId;
  final int totalMoves;
  final int hits;
  final int misses;
  final List<(int, int)> hitPositions; // Positions des coups touchés
  final List<(int, int)> missPositions; // Positions des coups manqués
  final Duration gameDuration;
  final DateTime recordedAt;
  final bool won;
  final int shipsDestroyed;
  final double accuracy; // (hits / totalMoves) * 100

  const GameStatistics({
    required this.gameId,
    required this.playerId,
    required this.opponentId,
    required this.totalMoves,
    required this.hits,
    required this.misses,
    required this.hitPositions,
    required this.missPositions,
    required this.gameDuration,
    required this.recordedAt,
    required this.won,
    required this.shipsDestroyed,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'playerId': playerId,
      'opponentId': opponentId,
      'totalMoves': totalMoves,
      'hits': hits,
      'misses': misses,
      'hitPositions': hitPositions
          .map((pos) => {'row': pos.$1, 'col': pos.$2})
          .toList(),
      'missPositions': missPositions
          .map((pos) => {'row': pos.$1, 'col': pos.$2})
          .toList(),
      'gameDuration': gameDuration.inSeconds,
      'recordedAt': recordedAt.toIso8601String(),
      'won': won,
      'shipsDestroyed': shipsDestroyed,
      'accuracy': accuracy,
    };
  }

  factory GameStatistics.fromJson(Map<String, dynamic> json) {
    return GameStatistics(
      gameId: json['gameId'] as String,
      playerId: json['playerId'] as String,
      opponentId: json['opponentId'] as String,
      totalMoves: json['totalMoves'] as int,
      hits: json['hits'] as int,
      misses: json['misses'] as int,
      hitPositions: (json['hitPositions'] as List)
          .map((pos) => (pos['row'] as int, pos['col'] as int))
          .toList(),
      missPositions: (json['missPositions'] as List)
          .map((pos) => (pos['row'] as int, pos['col'] as int))
          .toList(),
      gameDuration: Duration(seconds: json['gameDuration'] as int),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      won: json['won'] as bool,
      shipsDestroyed: json['shipsDestroyed'] as int,
      accuracy: json['accuracy'] as double,
    );
  }

  @override
  List<Object?> get props => [
        gameId,
        playerId,
        opponentId,
        totalMoves,
        hits,
        misses,
        hitPositions,
        missPositions,
        gameDuration,
        recordedAt,
        won,
        shipsDestroyed,
        accuracy,
      ];
}

class PlayerStatisticsAggregate extends Equatable {
  final String playerId;
  final int totalGames;
  final int totalWins;
  final int totalLosses;
  final double winRate;
  final double averageAccuracy;
  final int totalHits;
  final int totalMisses;
  final List<int> heatmap; // Matrice 10x10 sérialisée de fréquence de coups
  final Map<String, int> moveTiming; // Timing des coups (pour patterns)

  const PlayerStatisticsAggregate({
    required this.playerId,
    required this.totalGames,
    required this.totalWins,
    required this.totalLosses,
    required this.winRate,
    required this.averageAccuracy,
    required this.totalHits,
    required this.totalMisses,
    required this.heatmap,
    required this.moveTiming,
  });

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'totalGames': totalGames,
      'totalWins': totalWins,
      'totalLosses': totalLosses,
      'winRate': winRate,
      'averageAccuracy': averageAccuracy,
      'totalHits': totalHits,
      'totalMisses': totalMisses,
      'heatmap': heatmap,
      'moveTiming': moveTiming,
    };
  }

  factory PlayerStatisticsAggregate.fromJson(Map<String, dynamic> json) {
    return PlayerStatisticsAggregate(
      playerId: json['playerId'] as String,
      totalGames: json['totalGames'] as int,
      totalWins: json['totalWins'] as int,
      totalLosses: json['totalLosses'] as int,
      winRate: json['winRate'] as double,
      averageAccuracy: json['averageAccuracy'] as double,
      totalHits: json['totalHits'] as int,
      totalMisses: json['totalMisses'] as int,
      heatmap: List<int>.from(json['heatmap'] as List),
      moveTiming: Map<String, int>.from(json['moveTiming'] as Map),
    );
  }

  @override
  List<Object?> get props => [
        playerId,
        totalGames,
        totalWins,
        totalLosses,
        winRate,
        averageAccuracy,
        totalHits,
        totalMisses,
        heatmap,
        moveTiming,
      ];
}
