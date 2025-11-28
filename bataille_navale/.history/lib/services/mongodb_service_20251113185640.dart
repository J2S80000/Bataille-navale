import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/statistics.dart';

class MongoDBService {
  static const String _baseUrl = 'http://localhost:3000/api';
  static const Duration _timeout = Duration(seconds: 10);

  /// Initialize connection to MongoDB
  Future<void> initialize() async {
    if (!kIsWeb) {
      print('✓ MongoDB skipped on non-web platform');
      return;
    }
    try {
      // Test connection
      final response = await http.get(
        Uri.parse('http://localhost:3000/health'),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        print('✓ REST API connected successfully');
      }
    } catch (e) {
      print('⚠ REST API connection failed: $e (will retry on save)');
    }
  }

  /// Save game statistics to MongoDB via REST API
  Future<bool> saveGameStatistics(GameStatistics stats) async {
    if (!kIsWeb) return false;

    try {
      final payload = stats.toJson();
      payload['timestamp'] = DateTime.now().toIso8601String();

      final response = await http.post(
        Uri.parse('$_baseUrl/game_statistics'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✓ Statistic saved: ${stats.gameId}');
        return true;
      }
      print('⚠ Unexpected response: ${response.statusCode}');
      return false;
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
        Uri.parse('$_baseUrl/game_statistics'),
      ).timeout(_timeout);

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
        Uri.parse('$_baseUrl/game_statistics?playerId=$playerId'),
      ).timeout(_timeout);

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
        Uri.parse('$_baseUrl/game_statistics/$statsId'),
      ).timeout(_timeout);

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
        Uri.parse('$_baseUrl/games'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(_timeout);

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
        Uri.parse('$_baseUrl/games?playerId=$playerId'),
      ).timeout(_timeout);

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
