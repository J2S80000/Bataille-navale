import '../ai/neural_network.dart';
import '../models/index.dart';
import '../services/mongodb_service.dart';

/// Gestionnaire des modèles d'IA avec niveaux de difficulté et entraînement
class AIModelManager {
  /// Crée un nouveau modèle d'IA pour une difficulté donnée
  static NeuralNetworkAI createNewModel(String difficulty) {
    final model = NeuralNetworkAI(
      difficulty: difficulty,
      trainingIterations: 0,
    );

    // Ajuster le learning rate selon la difficulté
    switch (difficulty) {
      case 'easy':
        model.instanceLearningRate = 0.001; // Apprentissage lent
        break;
      case 'medium':
        model.instanceLearningRate = 0.005;
        break;
      case 'hard':
        model.instanceLearningRate = 0.01;
        break;
      case 'expert':
        model.instanceLearningRate = 0.02; // Apprentissage rapide
        break;
    }

    return model;
  }

  /// Initialise les modèles avec des entraînements de base
  static NeuralNetworkAI createInitializedModel(String difficulty) {
    final model = createNewModel(difficulty);
    
    // Créer des données d'entraînement factices pour initialiser les modèles
    // Cela simule quelques jeux d'apprentissage antérieurs
    final trainingData = <(List<double> input, List<double> target)>[];
    
    // Générer 10 exemples d'entraînement
    for (int game = 0; game < 10; game++) {
      final input = List<double>.filled(100, 0.0);
      final target = List<double>.filled(100, 0.0);
      
      // Ajouter quelques positions "touchées" aléatoires
      for (int i = 0; i < 5; i++) {
        int idx = (game * 10 + i) % 100;
        input[idx] = (game.toDouble() / 10.0); // Variation selon le "jeu"
        target[idx] = 1.0;
      }
      
      trainingData.add((input, target));
    }
    
    // Entraîner le modèle une fois
    if (trainingData.isNotEmpty) {
      model.trainEpochs(trainingData, 3); // 3 épochs pour initialiser
    }
    
    // Marquer comme initialisé
    model.trainingIterations = _getInitialTrainingCount(difficulty);
    
    return model;
  }

  /// Retourne le nombre d'entraînements initial selon la difficulté
  static int _getInitialTrainingCount(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 2; // Peu entraîné
      case 'medium':
        return 8; // Moyen
      case 'hard':
        return 15; // Bien entraîné
      case 'expert':
        return 35; // Très entraîné
      default:
        return 0;
    }
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

      // Si aucun modèle n'existe, créer les modèles initialisés avec entraînement de base
      if (models.isEmpty) {
        print('[AI] Initialisation des modèles IA...');
        models['easy'] = createInitializedModel('easy');
        models['medium'] = createInitializedModel('medium');
        models['hard'] = createInitializedModel('hard');
        models['expert'] = createInitializedModel('expert');
        
        // Sauvegarder les modèles initialisés en arrière-plan (sans attendre)
        for (final model in models.values) {
          saveModel(model, playerId, mongoService);
        }
      }

      return models;
    } catch (e) {
      print('Erreur chargement modèles IA: $e');
      // Retourner les modèles initialisés en cas d'erreur
      return {
        'easy': createInitializedModel('easy'),
        'medium': createInitializedModel('medium'),
        'hard': createInitializedModel('hard'),
        'expert': createInitializedModel('expert'),
      };
    }
  }

  /// Entraîne un modèle avec les patterns du joueur et les résultats des jeux
  static Future<NeuralNetworkAI> trainModel({
    required NeuralNetworkAI model,
    required List<GameStatistics> recentGames,
    required Map<String, dynamic> playerBehavior,
  }) async {
    if (recentGames.isEmpty) return model;

    // Préparer les données d'entraînement
    final trainingData = <(List<double> input, List<double> target)>[];

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

      // Convertir en input/output pour le réseau
      final input = heatmap.map((v) => (v / 2.0)).toList(); // Normaliser 0-1
      final output = heatmap.map((v) => (v == 1 ? 1.0 : 0.0)).toList();

      trainingData.add((input, output));
    }

    // Entraîner le modèle
    if (trainingData.isNotEmpty) {
      model.trainEpochs(trainingData, 20);
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
        'learningRate': models['easy']?.instanceLearningRate ?? 0.001,
      },
      'medium': {
        'difficulty': 'medium',
        'trainingIterations': models['medium']?.trainingIterations ?? 0,
        'learningRate': models['medium']?.instanceLearningRate ?? 0.005,
      },
      'hard': {
        'difficulty': 'hard',
        'trainingIterations': models['hard']?.trainingIterations ?? 0,
        'learningRate': models['hard']?.instanceLearningRate ?? 0.01,
      },
      'expert': {
        'difficulty': 'expert',
        'trainingIterations': models['expert']?.trainingIterations ?? 0,
        'learningRate': models['expert']?.instanceLearningRate ?? 0.02,
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
        report.writeln('${difficulty.toUpperCase()}:');
        report.writeln('  - Entraînements: ${model.trainingIterations}');
        report.writeln('  - Learning rate: ${model.instanceLearningRate}');
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
