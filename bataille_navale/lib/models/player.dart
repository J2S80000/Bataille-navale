import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String id;
  final String name;
  final String email;
  final int wins;
  final int losses;
  final int gamesPlayed;
  final DateTime createdAt;

  const Player({
    required this.id,
    required this.name,
    required this.email,
    this.wins = 0,
    this.losses = 0,
    this.gamesPlayed = 0,
    required this.createdAt,
  });

  double get winRate {
    if (gamesPlayed == 0) return 0.0;
    return wins / gamesPlayed;
  }

  Player copyWith({
    int? wins,
    int? losses,
    int? gamesPlayed,
  }) {
    return Player(
      id: id,
      name: name,
      email: email,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'wins': wins,
      'losses': losses,
      'gamesPlayed': gamesPlayed,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, name, email, wins, losses, gamesPlayed, createdAt];
}
