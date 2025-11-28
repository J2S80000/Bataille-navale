import 'package:equatable/equatable.dart';
import 'board.dart';
import 'move.dart';
import 'player.dart';

enum GameStatus {
  setup,      // Phase de placement des navires
  playing,    // En cours
  finished,   // Terminée
  abandoned,  // Abandonnée
}

class Game extends Equatable {
  final String id;
  final Player player1;
  final Player player2;
  final Board board1; // Plateau du joueur 1
  final Board board2; // Plateau du joueur 2
  final List<Move> moves; // Historique des coups
  final String currentTurnPlayerId; // ID du joueur qui doit jouer
  final String? winnerId;
  final GameStatus status;
  final DateTime createdAt;
  final DateTime? finishedAt;
  final bool player1IsAI;
  final bool player2IsAI;

  const Game({
    required this.id,
    required this.player1,
    required this.player2,
    required this.board1,
    required this.board2,
    required this.moves,
    required this.currentTurnPlayerId,
    this.winnerId,
    required this.status,
    required this.createdAt,
    this.finishedAt,
    this.player1IsAI = false,
    this.player2IsAI = false,
  });

  bool get isPlayer1Turn => currentTurnPlayerId == player1.id;
  bool get isPlayer2Turn => currentTurnPlayerId == player2.id;

  Player get currentPlayer {
    return isPlayer1Turn ? player1 : player2;
  }

  Player get opponent {
    return isPlayer1Turn ? player2 : player1;
  }

  Board get currentPlayerBoard => isPlayer1Turn ? board2 : board1;
  Board get currentPlayerShipBoard => isPlayer1Turn ? board1 : board2;

  int get totalMoves => moves.length;
  int get movesBy1 => moves.where((m) => m.playerId == player1.id).length;
  int get movesBy2 => moves.where((m) => m.playerId == player2.id).length;

  Game copyWith({
    Board? board1,
    Board? board2,
    List<Move>? moves,
    String? currentTurnPlayerId,
    String? winnerId,
    GameStatus? status,
    DateTime? finishedAt,
  }) {
    return Game(
      id: id,
      player1: player1,
      player2: player2,
      board1: board1 ?? this.board1,
      board2: board2 ?? this.board2,
      moves: moves ?? this.moves,
      currentTurnPlayerId: currentTurnPlayerId ?? this.currentTurnPlayerId,
      winnerId: winnerId ?? this.winnerId,
      status: status ?? this.status,
      createdAt: createdAt,
      finishedAt: finishedAt ?? this.finishedAt,
      player1IsAI: player1IsAI,
      player2IsAI: player2IsAI,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player1': player1.toJson(),
      'player2': player2.toJson(),
      'board1': board1.toJson(),
      'board2': board2.toJson(),
      'moves': moves.map((m) => m.toJson()).toList(),
      'currentTurnPlayerId': currentTurnPlayerId,
      'winnerId': winnerId,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
      'player1IsAI': player1IsAI,
      'player2IsAI': player2IsAI,
    };
  }

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] as String,
      player1: Player.fromJson(json['player1'] as Map<String, dynamic>),
      player2: Player.fromJson(json['player2'] as Map<String, dynamic>),
      board1: Board.fromJson(json['board1'] as Map<String, dynamic>),
      board2: Board.fromJson(json['board2'] as Map<String, dynamic>),
      moves: (json['moves'] as List)
          .map((m) => Move.fromJson(m as Map<String, dynamic>))
          .toList(),
      currentTurnPlayerId: json['currentTurnPlayerId'] as String,
      winnerId: json['winnerId'] as String?,
      status: GameStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => GameStatus.playing,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'] as String)
          : null,
      player1IsAI: json['player1IsAI'] as bool? ?? false,
      player2IsAI: json['player2IsAI'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        player1,
        player2,
        board1,
        board2,
        moves,
        currentTurnPlayerId,
        winnerId,
        status,
        createdAt,
        finishedAt,
        player1IsAI,
        player2IsAI,
      ];
}
