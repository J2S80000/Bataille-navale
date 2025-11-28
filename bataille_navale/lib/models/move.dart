import 'package:equatable/equatable.dart';

enum MoveResult {
  miss,      // Manqué
  hit,       // Touché
  sunk,      // Coulé
  invalid,   // Coup invalide
}

class Move extends Equatable {
  final String id;
  final int row;
  final int col;
  final MoveResult result;
  final DateTime timestamp;
  final String playerId; // Qui a joué ce coup

  const Move({
    required this.id,
    required this.row,
    required this.col,
    required this.result,
    required this.timestamp,
    required this.playerId,
  });

  String get position => '${String.fromCharCode(65 + col)}${row + 1}';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'row': row,
      'col': col,
      'result': result.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'playerId': playerId,
    };
  }

  factory Move.fromJson(Map<String, dynamic> json) {
    return Move(
      id: json['id'] as String,
      row: json['row'] as int,
      col: json['col'] as int,
      result: MoveResult.values.firstWhere(
        (e) => e.toString().split('.').last == json['result'],
        orElse: () => MoveResult.invalid,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      playerId: json['playerId'] as String,
    );
  }

  @override
  List<Object?> get props => [id, row, col, result, timestamp, playerId];
}
