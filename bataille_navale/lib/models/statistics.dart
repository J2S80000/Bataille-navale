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
  final List<(int, int)> playerShipPositions; // Positions des navires du joueur
  final List<(int, int)> opponentShipPositions; // Positions des navires de l'adversaire détruites
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
    required this.playerShipPositions,
    required this.opponentShipPositions,
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
      'playerShipPositions': playerShipPositions
          .map((pos) => {'row': pos.$1, 'col': pos.$2})
          .toList(),
      'opponentShipPositions': opponentShipPositions
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
    // Helper functions to safely parse values
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      return false;
    }

    List<(int, int)> parsePositions(dynamic value) {
      if (value is! List) return [];
      return (value as List)
          .map((pos) {
            if (pos is Map) {
              return (
                parseInt(pos['row']),
                parseInt(pos['col']),
              );
            }
            return (0, 0);
          })
          .toList();
    }

    return GameStatistics(
      gameId: json['gameId']?.toString() ?? 'unknown',
      playerId: json['playerId']?.toString() ?? 'unknown',
      opponentId: json['opponentId']?.toString() ?? 'unknown',
      totalMoves: parseInt(json['totalMoves']),
      hits: parseInt(json['hits']),
      misses: parseInt(json['misses']),
      hitPositions: parsePositions(json['hitPositions']),
      missPositions: parsePositions(json['missPositions']),
      playerShipPositions: parsePositions(json['playerShipPositions']),
      opponentShipPositions: parsePositions(json['opponentShipPositions']),
      gameDuration: Duration(seconds: parseInt(json['gameDuration'])),
      recordedAt: json['recordedAt'] != null 
          ? DateTime.parse(json['recordedAt'].toString())
          : DateTime.now(),
      won: parseBool(json['won']),
      shipsDestroyed: parseInt(json['shipsDestroyed']),
      accuracy: parseDouble(json['accuracy']),
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
        playerShipPositions,
        opponentShipPositions,
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
