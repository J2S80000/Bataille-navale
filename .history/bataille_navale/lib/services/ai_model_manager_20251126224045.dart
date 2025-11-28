import '../ai/neural_network.dart';
import '../models/index.dart';
import '../services/mongodb_service.dart';

/// Gestionnaire des modèles d'IA avec niveaux de difficulté et entraînement
class AIModelManager {
  static const String _modelsCollectionKey = 'ai_models';

  /// Crée un nouveau modèle d'IA pour une difficulté donnée
  static NeuralNetworkAI createNewModel(String difficulty) {
    return NeuralNetworkAI();
  }

  /// Charge tous les modèles d'IA d'un utilisateur depuis MongoDB
  static Future<Map<String, NeuralNetworkAI>> loadUserModels(
    String playerId,
    MongoDBService mongoService,
  ) async {
    try {
      // Récupérer les modèles depuis MongoDB
      final response = await mongoService.getGameHistory(playerId);
      final models = <String, NeuralNetworkAI>{};

      for (final doc in response) {
        if (doc['type'] == 'ai_model') {
          final model = NeuralNetworkAI.fromJson(doc);
          models[model.difficulty] = model;
        }
      }

      // Si aucun modèle n'existe, créer les modèles par défaut
      if (models.isEmpty) {
        models['easy'] = _createDefaultModel('easy', 0);
        models['medium'] = _createDefaultModel('medium', 0);
        models['hard'] = _createDefaultModel('hard', 0);
        models['expert'] = _createDefaultModel('expert', 0);
      }

      return models;
    } catch (e) {
      print('Erreur chargement modèles IA: $e');
      // Retourner les modèles par défaut en cas d'erreur
      return {
        'easy': _createDefaultModel('easy', 0),
        'medium': _createDefaultModel('medium', 0),
        'hard': _createDefaultModel('hard', 0),
        'expert': _createDefaultModel('expert', 0),
      };
    }
  }

  /// Crée un modèle par défaut avec des weights pré-initialisés
  static NeuralNetworkAI _createDefaultModel(String difficulty, int trainingCount) {
    final model = NeuralNetworkAI();
    model.difficulty = difficulty;
    model.trainingIterations = trainingCount;

    // Ajuster le learning rate selon la difficulté
    switch (difficulty) {
      case 'easy':
        model.learningRate = 0.001; // Apprentissage lent
        break;
      case 'medium':
        model.learningRate = 0.005;
        break;
      case 'hard':
        model.learningRate = 0.01;
        break;
      case 'expert':
        model.learningRate = 0.02; // Apprentissage rapide
        break;
    }

    return model;
  }

  /// Entraîne un modèle avec les patterns du joueur et les résultats des jeux
  static Future<NeuralNetworkAI> trainModel({
    required NeuralNetworkAI model,
    required List<GameStatistics> recentGames,
    required Map<String, dynamic> playerBehavior,
  }) async {
    if (recentGames.isEmpty) return model;

    // Préparer les données d'entraînement
    final trainingData = <(List<int> boardState, bool isShipPresent)>[];

    // Analyser chaque partie pour créer des exemples d'entraînement
    for (final game in recentGames) {
      // Créer une heatmap des positions touchées
      final heatmap = List<int>.filled(100, 0); // 0 = vide, 1 = touché, 2 = manqué

      for (final (row, col) in game.hitPositions) {
        heatmap[row * 10 + col] = 1; // Navire présent (touché)
      }

      for (final (row, col) in game.missPositions) {
        heatmap[row * 10 + col] = 2; // Pas de navire (manqué)
      }

      // Ajouter les patterns comme données d'entraînement
      for (int i = 0; i < 100; i++) {
        final isShipArea = heatmap[i] == 1; // 1 = navire
        trainingData.add((heatmap, isShipArea));
      }
    }

    // Entraîner le modèle
    if (trainingData.isNotEmpty) {
      model.train(trainingData, epochs: 20);
      model.trainingIterations++;
    }

    return model;
  }

  /// Sauvegarde un modèle dans MongoDB
  static Future<bool> saveModel(
    NeuralNetworkAI model,
    String playerId,
    MongoDBService mongoService,
  ) async {
    try {
      final modelData = {
        ...model.toJson(),
        'playerId': playerId,
        'type': 'ai_model',
        'savedAt': DateTime.now().toIso8601String(),
      };

      await mongoService.saveGameState(modelData);
      print('✓ Modèle ${model.difficulty} sauvegardé (itérations: ${model.trainingIterations})');
      return true;
    } catch (e) {
      print('Erreur sauvegarde modèle: $e');
      return false;
    }
  }

  /// Sélectionne un modèle selon la difficulté demandée
  static NeuralNetworkAI selectModelByDifficulty(
    Map<String, NeuralNetworkAI> models,
    String difficulty,
  ) {
    return models[difficulty] ?? models['medium']!;
  }

  /// Retourne les stats d'entraînement des modèles
  static Map<String, dynamic> getModelsStats(Map<String, NeuralNetworkAI> models) {
    return {
      'easy': {
        'difficulty': 'easy',
        'trainingIterations': models['easy']?.trainingIterations ?? 0,
        'learningRate': models['easy']?.learningRate ?? 0.001,
      },
      'medium': {
        'difficulty': 'medium',
        'trainingIterations': models['medium']?.trainingIterations ?? 0,
        'learningRate': models['medium']?.learningRate ?? 0.005,
      },
      'hard': {
        'difficulty': 'hard',
        'trainingIterations': models['hard']?.trainingIterations ?? 0,
        'learningRate': models['hard']?.learningRate ?? 0.01,
      },
      'expert': {
        'difficulty': 'expert',
        'trainingIterations': models['expert']?.trainingIterations ?? 0,
        'learningRate': models['expert']?.learningRate ?? 0.02,
      },
    };
  }

  /// Génère un rapport d'entraînement
  static String generateTrainingReport(Map<String, NeuralNetworkAI> models) {
    final report = StringBuffer();
    report.writeln('📊 Rapport d\'entraînement des modèles IA');
    report.writeln('=' * 50);

    for (final difficulty in ['easy', 'medium', 'hard', 'expert']) {
      final model = models[difficulty];
      if (model != null) {
        report.writeln('');
        report.writeln('$difficulty.toUpperCase():');
        report.writeln('  - Entraînements: ${model.trainingIterations}');
        report.writeln('  - Learning rate: ${model.learningRate}');
        report.writeln('  - Force: ${_getStrengthDescription(model.trainingIterations)}');
      }
    }

    return report.toString();
  }

  static String _getStrengthDescription(int trainingIterations) {
    if (trainingIterations < 5) return '⭐ Très faible';
    if (trainingIterations < 15) return '⭐⭐ Faible';
    if (trainingIterations < 30) return '⭐⭐⭐ Moyen';
    if (trainingIterations < 50) return '⭐⭐⭐⭐ Fort';
    return '⭐⭐⭐⭐⭐ Très fort';
  }
}
