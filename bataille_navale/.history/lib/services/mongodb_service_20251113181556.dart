import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/statistics.dart';

class MongoDBService {
  static const String _baseUrl = 'http://localhost:27018';
  static const String _dbName = 'bataille_navale';
  static const String _statsCollection = 'game_statistics';
  static const String _gamesCollection = 'games';

  /// Initialize connection to MongoDB
  Future<void> initialize() async {
    if (!kIsWeb) {
      print('✓ MongoDB skipped on non-web platform');
      return;
    }
    try {
      // Test connection
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/ping'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        print('✓ MongoDB connected successfully');
      }
    } catch (e) {
      print('⚠ MongoDB connection failed: $e (will use local storage)');
    }
  }

  /// Save game statistics to MongoDB
  Future<bool> saveGameStatistics(GameStatistics stats) async {
    if (!kIsWeb) return false;

    try {
      final payload = stats.toJson();
      payload['timestamp'] = DateTime.now().toIso8601String();

      final response = await http.post(
        Uri.parse('$_baseUrl/$_dbName/$_statsCollection'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('⚠ Failed to save statistics: $e');
      return false;
    }
  }

  /// Get all game statistics from MongoDB
  Future<List<GameStatistics>> getAllGameStatistics() async {
    if (!kIsWeb) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$_dbName/$_statsCollection'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((e) => GameStatistics.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('⚠ Failed to fetch statistics: $e');
      return [];
    }
  }

  /// Get statistics for a specific player
  Future<List<GameStatistics>> getPlayerStatistics(String playerId) async {
    if (!kIsWeb) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$_dbName/$_statsCollection?playerId=$playerId'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((e) => GameStatistics.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('⚠ Failed to fetch player statistics: $e');
      return [];
    }
  }

  /// Delete game statistics
  Future<bool> deleteGameStatistics(String statsId) async {
    if (!kIsWeb) return false;

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$_dbName/$_statsCollection/$statsId'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('⚠ Failed to delete statistics: $e');
      return false;
    }
  }

  /// Save game state to MongoDB
  Future<bool> saveGameState(Map<String, dynamic> gameData) async {
    if (!kIsWeb) return false;

    try {
      final payload = {
        ...gameData,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/$_dbName/$_gamesCollection'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('⚠ Failed to save game state: $e');
      return false;
    }
  }

  /// Get game history
  Future<List<Map<String, dynamic>>> getGameHistory(String playerId) async {
    if (!kIsWeb) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$_dbName/$_gamesCollection?playerId=$playerId'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('⚠ Failed to fetch game history: $e');
      return [];
    }
  }
}
