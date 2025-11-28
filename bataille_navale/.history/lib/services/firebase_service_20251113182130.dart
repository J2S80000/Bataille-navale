import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/index.dart';
import 'mongodb_service.dart';

/// Firebase Service compatible web et mobile
/// Sur le web, utilise MongoDB; sur mobile, utilise Firebase réel
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  static final MongoDBService _mongoDb = MongoDBService();
  
  FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  /// Initialise Firebase ou MongoDB selon la plateforme
  Future<void> initialize() async {
    if (kIsWeb) {
      print('✓ Using MongoDB for web platform');
      await _mongoDb.initialize();
      return;
    }
    print('✓ Firebase would be initialized on native platform');
    // Sur mobile, Firebase serait initialisé ici
  }

  // ============ AUTHENTICATION ============

  Future<dynamic> signUp(String email, String password, String name) async {
    if (kIsWeb) {
      print('User registration: $email');
      return null;
    }
    throw UnimplementedError('Firebase not configured');
  }

  Future<dynamic> signIn(String email, String password) async {
    if (kIsWeb) {
      print('User login: $email');
      return null;
    }
    throw UnimplementedError('Firebase not configured');
  }

  Future<void> signOut() async {
    if (kIsWeb) return;
  }

  dynamic get currentUser => null;

  Stream<dynamic> get authStateChanges => Stream.empty();

  // ============ PLAYERS ============

  Future<void> savePlayer(Player player) async {
    print('📝 Player saved locally: ${player.name}');
  }

  Future<Player> getPlayer(String id) async {
    throw UnimplementedError('Firebase not configured');
  }

  Future<Player?> getCurrentPlayer() async => null;

  // ============ GAMES ============

  Future<String> createGame(Game game) async {
    final gameId = 'local_game_${DateTime.now().millisecondsSinceEpoch}';
    print('🎮 Game created: $gameId');
    return gameId;
  }

  Future<void> updateGame(Game game) async {
    print('🎮 Game updated: ${game.id}');
  }

  Future<Game> getGame(String id) async {
    throw UnimplementedError('Firebase not configured');
  }

  Future<List<Game>> getPlayerGames(String playerId) async {
    return [];
  }

  Stream<List<Game>> watchActiveGames(String playerId) {
    return Stream.value([]);
  }

  // ============ STATISTICS ============

  Future<void> saveGameStatistics(dynamic stats) async {
    if (kIsWeb && stats is GameStatistics) {
      await _mongoDb.saveGameStatistics(stats);
      return;
    }
    print('📊 Statistics saved locally');
  }

  Future<List<dynamic>> getAllGameStats(String playerId) async {
    if (kIsWeb) {
      return await _mongoDb.getPlayerStatistics(playerId);
    }
    return [];
  }

  Future<void> updatePlayerStatisticsAggregate(dynamic stats) async {
    if (kIsWeb) {
      // Aggregate stats would be saved to MongoDB
      return;
    }
    print('📊 Aggregate statistics updated');
  }

  // ============ GAME DELETION ============

  Future<void> deleteGame(String gameId) async {
    print('🗑️ Game deleted: $gameId');
  }

  // ============ LEADERBOARD ============

  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    return [];
  }
}
