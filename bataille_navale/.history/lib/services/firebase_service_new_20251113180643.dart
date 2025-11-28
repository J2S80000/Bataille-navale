import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/index.dart';

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
      return;
    }
    print('Firebase initialization skipped (web-only stub)');
  }

  // ============ AUTHENTICATION ============

  Future<dynamic> signUp(String email, String password, String name) async {
    if (kIsWeb) return null;
    throw UnimplementedError('Firebase not available');
  }

  Future<dynamic> signIn(String email, String password) async {
    if (kIsWeb) return null;
    throw UnimplementedError('Firebase not available');
  }

  Future<void> signOut() async {
    if (kIsWeb) return;
  }

  dynamic get currentUser => null;

  Stream<dynamic> get authStateChanges => Stream.empty();

  // ============ PLAYERS ============

  Future<void> savePlayer(Player player) async {
    print('Player save skipped: ${player.name}');
  }

  Future<Player> getPlayer(String id) async {
    throw UnimplementedError('Firebase not available');
  }

  Future<Player?> getCurrentPlayer() async => null;

  // ============ GAMES ============

  Future<String> createGame(Game game) async {
    print('Game creation skipped');
    return 'web_game_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> updateGame(Game game) async {
    print('Game update skipped');
  }

  Future<Game> getGame(String id) async {
    throw UnimplementedError('Firebase not available');
  }

  Future<List<Game>> getPlayerGames(String playerId) async {
    return [];
  }

  Stream<List<Game>> watchActiveGames(String playerId) {
    return Stream.value([]);
  }

  // ============ STATISTICS ============

  Future<void> saveGameStatistics(dynamic stats) async {
    print('Stats save skipped');
  }

  Future<List<dynamic>> getAllGameStats(String playerId) async {
    return [];
  }

  Future<void> updatePlayerStatisticsAggregate(dynamic stats) async {
    print('Aggregate stats update skipped');
  }

  // ============ GAME DELETION ============

  Future<void> deleteGame(String gameId) async {
    print('Game deletion skipped');
  }
}
