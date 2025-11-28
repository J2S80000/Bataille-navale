import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/index.dart';

// Import conditional
export 'firebase_service_web.dart' if (dart.library.html) 'firebase_service_web.dart' if (dart.library.io) 'firebase_service_native.dart';

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
    print('Firebase initialization on native platform');
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
    throw UnimplementedError('Firebase not available');
  }

  dynamic get currentUser => null;

  Stream<dynamic> get authStateChanges => Stream.empty();

  // ============ PLAYERS ============

  Future<void> savePlayer(Player player) async {
    if (kIsWeb) {
      print('Player save skipped on web: ${player.name}');
      return;
    }
  }

  Future<Player> getPlayer(String id) async {
    throw UnimplementedError('Firebase not available');
  }

  Future<Player?> getCurrentPlayer() async => null;

  // ============ GAMES ============

  Future<String> createGame(Game game) async {
    if (kIsWeb) {
      print('Game creation skipped on web');
      return 'web_game_${DateTime.now().millisecondsSinceEpoch}';
    }
    throw UnimplementedError('Firebase not available');
  }

  Future<void> updateGame(Game game) async {
    if (kIsWeb) {
      print('Game update skipped on web');
      return;
    }
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
    if (kIsWeb) {
      print('Stats save skipped on web');
      return;
    }
  }

  Future<List<dynamic>> getAllGameStats(String playerId) async {
    return [];
  }

  Future<void> updatePlayerStatisticsAggregate(dynamic stats) async {
    if (kIsWeb) {
      print('Aggregate stats update skipped on web');
      return;
    }
  }

  // ============ GAME DELETION ============

  Future<void> deleteGame(String gameId) async {
    if (kIsWeb) {
      print('Game deletion skipped on web');
      return;
    }
  }
}
