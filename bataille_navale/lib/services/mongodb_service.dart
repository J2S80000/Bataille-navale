import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html show window;
import '../models/statistics.dart';

class MongoDBService {
  // Pour le web, utilise l'URL du host machine
  static String get _baseUrl {
    if (kIsWeb) {
      // Sur le web, on peut pas utiliser localhost - faut utiliser l'URL actuelle
      final hostname = html.window.location.hostname ?? 'localhost';
      return 'http://$hostname:3000/api';
    }
    return 'http://localhost:3000/api';
  }
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

  /// Save game statistics to MongoDB via REST API with retry logic
  Future<bool> saveGameStatistics(GameStatistics stats) async {
    if (!kIsWeb) return false;

    int retries = 0;
    const maxRetries = 2;

    while (retries <= maxRetries) {
      try {
        final payload = stats.toJson();
        payload['timestamp'] = DateTime.now().toIso8601String();

        final response = await http.post(
          Uri.parse('$_baseUrl/game_statistics'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(_timeout);

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('[MONGODB] ✓ Statistic saved: ${stats.gameId}');
          return true;
        }
        
        // If server error, retry
        if (response.statusCode >= 500) {
          retries++;
          if (retries <= maxRetries) {
            print('[MONGODB] Retry ${retries}/${maxRetries} for ${stats.gameId}');
            await Future.delayed(Duration(milliseconds: 200 * retries));
            continue;
          }
        }
        
        print('[MONGODB] ⚠ Unexpected response: ${response.statusCode}');
        return false;
      } catch (e) {
        retries++;
        if (retries <= maxRetries) {
          print('[MONGODB] Retry ${retries}/${maxRetries}: $e');
          await Future.delayed(Duration(milliseconds: 200 * retries));
          continue;
        }
        print('[MONGODB] ✗ Failed to save statistics after $maxRetries retries: $e');
        return false;
      }
    }
    
    return false;
  }

  /// Sauvegarde plusieurs parties d'un coup (batch) - BEAUCOUP PLUS RAPIDE
  Future<Map<String, dynamic>> saveGameStatisticsBatch(List<GameStatistics> stats) async {
    if (!kIsWeb) return {'savedCount': 0, 'failedCount': 0};

    try {
      final payload = stats.map((s) => s.toJson()).toList();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/game_statistics/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        print('[MONGODB] ✓ Batch sauvegardé: ${result['insertedCount']}/${stats.length} parties');
        return {
          'savedCount': result['insertedCount'] ?? 0,
          'failedCount': stats.length - (result['insertedCount'] ?? 0),
        };
      }
      
      print('[MONGODB] ✗ Batch failed: ${response.statusCode}');
      return {'savedCount': 0, 'failedCount': stats.length};
    } catch (e) {
      print('[MONGODB] ✗ Batch error: $e');
      return {'savedCount': 0, 'failedCount': stats.length};
    }
  }
  Future<List<GameStatistics>> getAllGameStatistics() async {
    if (!kIsWeb) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/game_statistics'),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // L'API retourne { data: [...], total, limit, skip, hasMore }
        final List<dynamic> data = responseData['data'] ?? [];
        
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

  /// Get statistics for a specific player - loads ALL records with pagination
  Future<List<GameStatistics>> getPlayerStatistics(String playerId, {int maxRecords = 1000}) async {
    if (!kIsWeb) return [];

    try {
      print('[MONGODB] Fetching stats for playerId: $playerId (max: $maxRecords)');
      
      List<GameStatistics> allStats = [];
      int skip = 0;
      const int limit = 5000; // Max per request
      bool hasMore = true;
      int totalRecords = 0;

      while (hasMore && totalRecords < maxRecords) {
        print('[MONGODB] Fetching batch: skip=$skip, limit=$limit');
        
        final response = await http.get(
          Uri.parse('$_baseUrl/game_statistics?playerId=$playerId&limit=$limit&skip=$skip'),
        ).timeout(_timeout);

        if (response.statusCode == 200) {
          final dynamic decodedBody = jsonDecode(response.body);
          
          // Gérer les deux cas: direct array ou objet avec data
          List<dynamic> data = [];
          int total = 0;
          
          if (decodedBody is List) {
            data = decodedBody;
            hasMore = false;
          } else if (decodedBody is Map) {
            data = decodedBody['data'] ?? [];
            total = decodedBody['total'] ?? 0;
            hasMore = decodedBody['hasMore'] ?? false;
            
            print('[MONGODB] Response: ${data.length} records, total=$total, hasMore=$hasMore');
          }
          
          // Convertir et ajouter (limiter au max)
          for (final item in data) {
            if (totalRecords >= maxRecords) break;
            try {
              final stat = GameStatistics.fromJson(item as Map<String, dynamic>);
              allStats.add(stat);
              totalRecords++;
            } catch (e) {
              print('[MONGODB] ⚠ Error parsing item: $e');
            }
          }
          
          if (!hasMore || totalRecords >= maxRecords) break;
          skip += limit;
        } else {
          print('[MONGODB] Status ${response.statusCode}: ${response.body}');
          break;
        }
      }
      
      print('[MONGODB] ✓ Loaded ${allStats.length} records (limited to $maxRecords)');
      return allStats;
    } catch (e, stackTrace) {
      print('⚠ Failed to fetch player statistics: $e');
      print('Stack trace: $stackTrace');
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

  /// Save AI model to MongoDB
  Future<bool> saveAIModel(Map<String, dynamic> modelData) async {
    if (!kIsWeb) return false;

    try {
      final payload = {
        ...modelData,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('[MONGODB] Tentative de sauvegarde du modèle IA: ${modelData['difficulty']}');
      
      // Essayer l'endpoint dédié d'abord
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/ai_models'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(_timeout);

        print('[MONGODB] Réponse serveur (ai_models): ${response.statusCode}');
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          print('[MONGODB] ✓ Modèle IA sauvegardé via /ai_models');
          return true;
        }
      } catch (e) {
        print('[MONGODB] ⚠ Endpoint /ai_models indisponible: $e');
      }
      
      // Fallback: utiliser saveGameState
      print('[MONGODB] Fallback: utilisation de /games pour sauvegarder le modèle');
      return await saveGameState(payload);
      
    } catch (e) {
      print('[MONGODB] ✗ Erreur sauvegarde modèle IA: $e');
      return false;
    }
  }

  /// Get all AI models for a player from MongoDB
  Future<List<Map<String, dynamic>>> getPlayerAIModels(String playerId) async {
    if (!kIsWeb) return [];

    try {
      print('[MONGODB] Récupération des modèles IA pour $playerId');
      
      // Essayer l'endpoint dédié d'abord
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/ai_models?playerId=$playerId'),
        ).timeout(_timeout);

        print('[MONGODB] Réponse serveur (ai_models): ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          print('[MONGODB] ✓ Modèles trouvés via /ai_models: ${data.length}');
          return List<Map<String, dynamic>>.from(data);
        }
      } catch (e) {
        print('[MONGODB] ⚠ Endpoint /ai_models indisponible: $e');
      }
      
      // Fallback: récupérer depuis getGameHistory et filtrer
      print('[MONGODB] Fallback: utilisation de /games pour récupérer les modèles');
      final allData = await getGameHistory(playerId);
      final aiModels = allData
          .where((doc) => doc['type'] == 'ai_model')
          .toList();
      print('[MONGODB] Modèles IA trouvés via fallback: ${aiModels.length}');
      return aiModels;
      
    } catch (e) {
      print('[MONGODB] ✗ Erreur récupération modèles IA: $e');
      return [];
    }
  }
}
