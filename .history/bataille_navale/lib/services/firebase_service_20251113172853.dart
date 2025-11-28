import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/index.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  
  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;

  FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  /// Initialise Firebase
  Future<void> initialize() async {
    await Firebase.initializeApp();
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
  }

  // ============ AUTHENTICATION ============

  /// Crée un compte utilisateur
  Future<User?> signUp(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Sauvegarde le profil
      final player = Player(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );
      
      await _firestore.collection('players').doc(player.id).set(player.toJson());
      
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception('Erreur d\'inscription: ${e.message}');
    }
  }

  /// Connexion utilisateur
  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception('Erreur de connexion: ${e.message}');
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Obtient l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  /// Stream de l'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============ PLAYERS ============

  /// Crée ou met à jour un joueur
  Future<void> savePlayer(Player player) async {
    await _firestore.collection('players').doc(player.id).set(
      player.toJson(),
      SetOptions(merge: true),
    );
  }

  /// Récupère un joueur
  Future<Player> getPlayer(String id) async {
    final doc = await _firestore.collection('players').doc(id).get();
    if (!doc.exists) throw Exception('Joueur non trouvé');
    return Player.fromJson(doc.data()!);
  }

  /// Récupère le profil actuel
  Future<Player?> getCurrentPlayer() async {
    if (currentUser == null) return null;
    return getPlayer(currentUser!.uid);
  }

  // ============ GAMES ============

  /// Crée une nouvelle partie
  Future<String> createGame(Game game) async {
    final docRef = await _firestore.collection('games').add(game.toJson());
    return docRef.id;
  }

  /// Met à jour une partie
  Future<void> updateGame(Game game) async {
    await _firestore.collection('games').doc(game.id).set(
      game.toJson(),
      SetOptions(merge: true),
    );
  }

  /// Récupère une partie
  Future<Game> getGame(String id) async {
    final doc = await _firestore.collection('games').doc(id).get();
    if (!doc.exists) throw Exception('Partie non trouvée');
    final data = doc.data()!;
    data['id'] = id;
    return Game.fromJson(data);
  }

  /// Récupère les parties d'un joueur
  Future<List<Game>> getPlayerGames(String playerId) async {
    final snapshot = await _firestore
        .collection('games')
        .where(FieldPath.documentId, isEqualTo: playerId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Game.fromJson(data);
    }).toList();
  }

  /// Stream des parties actives
  Stream<List<Game>> watchActiveGames(String playerId) {
    return _firestore
        .collection('games')
        .where('status', isNotEqualTo: 'finished')
        .orderBy('status')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Game.fromJson(data);
        }).toList());
  }

  // ============ STATISTICS ============

  /// Enregistre les stats d'une partie
  Future<void> saveGameStatistics(GameStatistics stats) async {
    await _firestore
        .collection('players')
        .doc(stats.playerId)
        .collection('game_stats')
        .doc(stats.gameId)
        .set(stats.toJson());
  }

  /// Récupère les stats d'une partie
  Future<GameStatistics> getGameStatistics(String playerId, String gameId) async {
    final doc = await _firestore
        .collection('players')
        .doc(playerId)
        .collection('game_stats')
        .doc(gameId)
        .get();
    if (!doc.exists) throw Exception('Stats non trouvées');
    return GameStatistics.fromJson(doc.data()!);
  }

  /// Met à jour les stats agrégées d'un joueur
  Future<void> updatePlayerStatisticsAggregate(
    PlayerStatisticsAggregate stats,
  ) async {
    await _firestore
        .collection('players')
        .doc(stats.playerId)
        .collection('aggregate')
        .doc('stats')
        .set(stats.toJson(), SetOptions(merge: true));
  }

  /// Récupère les stats agrégées
  Future<PlayerStatisticsAggregate?> getPlayerStatisticsAggregate(
    String playerId,
  ) async {
    try {
      final doc = await _firestore
          .collection('players')
          .doc(playerId)
          .collection('aggregate')
          .doc('stats')
          .get();
      if (!doc.exists) return null;
      return PlayerStatisticsAggregate.fromJson(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  /// Récupère l'historique des coups pour analyse
  Future<List<Move>> getGameMoves(String gameId) async {
    final snapshot = await _firestore
        .collection('games')
        .doc(gameId)
        .collection('moves')
        .orderBy('timestamp')
        .get();

    return snapshot.docs
        .map((doc) => Move.fromJson(doc.data()))
        .toList();
  }

  /// Sauvegarde un coup
  Future<void> saveMove(String gameId, Move move) async {
    await _firestore
        .collection('games')
        .doc(gameId)
        .collection('moves')
        .doc(move.id)
        .set(move.toJson());
  }

  // ============ LEADERBOARD ============

  /// Récupère le top 100 des joueurs
  Future<List<Player>> getLeaderboard({int limit = 100}) async {
    final snapshot = await _firestore
        .collection('players')
        .orderBy('wins', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => Player.fromJson(doc.data()))
        .toList();
  }

  /// Récupère les top 10 des meilleurs taux de précision
  Future<List<(String, double)>> getTopAccuracy({int limit = 10}) async {
    final snapshot = await _firestore
        .collectionGroup('aggregate')
        .where('totalGames', isGreaterThanOrEqualTo: 5)
        .orderBy('totalGames', descending: true)
        .orderBy('averageAccuracy', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => (
              doc['playerId'] as String,
              doc['averageAccuracy'] as double,
            ))
        .toList();
  }

  // ============ BATCH OPERATIONS ============

  /// Supprime une partie (dev only)
  Future<void> deleteGame(String gameId) async {
    await _firestore.collection('games').doc(gameId).delete();
  }

  /// Collecte tous les coups pour analyse IA
  Future<List<GameStatistics>> getAllGameStats(String playerId) async {
    final snapshot = await _firestore
        .collection('players')
        .doc(playerId)
        .collection('game_stats')
        .orderBy('recordedAt', descending: true)
        .limit(500) // Limite pour l'entraînement IA
        .get();

    return snapshot.docs
        .map((doc) => GameStatistics.fromJson(doc.data()))
        .toList();
  }
}
