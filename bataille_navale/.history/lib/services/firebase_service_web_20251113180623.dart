import 'package:flutter/foundation.dart';
import '../models/index.dart';

/// Version web-compatible du FirebaseService
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  
  FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  /// Initialise Firebase (no-op sur web)
  Future<void> initialize() async {
    if (kIsWeb) {
      print('Firebase skipped on web platform');
    }
  }

  // ============ AUTHENTICATION ============

  Future<dynamic> signUp(String email, String password, String name) async {
    throw UnimplementedError('Firebase not available on web');
  }

  Future<dynamic> signIn(String email, String password) async {
    throw UnimplementedError('Firebase not available on web');
  }

  Future<void> signOut() async {
    throw UnimplementedError('Firebase not available on web');
  }

  dynamic get currentUser => null;

  Stream<dynamic> get authStateChanges => Stream.empty();

  // ============ PLAYERS ============

  Future<void> savePlayer(Player player) async {
    print('Player save skipped on web: ${player.name}');
  }

  Future<Player> getPlayer(String id) async {
    throw UnimplementedError('Firebase not available on web');
  }

  Future<Player?> getCurrentPlayer() async => null;

  // ============ GAMES ============

  Future<String> createGame(Game game) async {
    print('Game creation skipped on web');
    return 'web_game_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> updateGame(Game game) async {
    print('Game update skipped on web');
  }

  Future<Game> getGame(String id) async {
    throw UnimplementedError('Firebase not available on web');
  }

  Future<List<Game>> getPlayerGames(String playerId) async {
    return [];
  }

  Stream<List<Game>> watchActiveGames(String playerId) {
    return Stream.value([]);
  }

  // ============ STATISTICS ============

  Future<void> saveGameStatistics(dynamic stats) async {
    print('Stats save skipped on web');
  }

  Future<List<dynamic>> getAllGameStats(String playerId) async {
    return [];
  }

  Future<void> updatePlayerStatisticsAggregate(dynamic stats) async {
    print('Aggregate stats update skipped on web');
  }

  // ============ GAME DELETION ============

  Future<void> deleteGame(String gameId) async {
    print('Game deletion skipped on web');
  }
}
