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

  /// Charge tous les modèles d'IA d'un utilisateur depuis MongoDB
  static Future<Map<String, NeuralNetworkAI>> loadUserModels(
    String playerId,
    MongoDBService mongoService,
  ) async {
    try {
      print('[LOAD] === Chargement des modèles pour $playerId ===');
      
      // Récupérer les modèles IA spécifiquement depuis l'endpoint dédié
      final response = await mongoService.getPlayerAIModels(playerId);
      print('[LOAD] Nombre de modèles IA trouvés: ${response.length}');
      for (final doc in response) {
        print('[LOAD]   - ${doc['difficulty']}: ${doc['trainingIterations']} entraînements');
      }
      
      final models = <String, NeuralNetworkAI>{};
      final difficulties = ['easy', 'medium', 'hard', 'expert'];

      // Charger les modèles pour chaque difficulté
      for (final difficulty in difficulties) {
        print('[LOAD] Recherche du modèle $difficulty...');
        
        // Rechercher le modèle pour cette difficulté
        final modelData = response.firstWhere(
          (doc) => doc['difficulty'] == difficulty,
          orElse: () => <String, dynamic>{},
        );

        if (modelData.isNotEmpty) {
          try {
            print('[LOAD]   ✓ Document trouvé pour $difficulty');
            print('[LOAD]   Entraînements sauvegardés: ${modelData['trainingIterations']}');
            
            final model = NeuralNetworkAI.fromJson(modelData);
            models[difficulty] = model;
            print('[LOAD] ✓ Modèle $difficulty chargé: ${model.trainingIterations} entraînements');
          } catch (e) {
            print('[LOAD] ✗ Erreur lors du chargement du modèle $difficulty: $e');
            models[difficulty] = createNewModel(difficulty);
          }
        } else {
          // Si aucun modèle trouvé pour cette difficulté, créer un par défaut
          print('[LOAD]   ✗ Aucun document trouvé pour $difficulty');
          models[difficulty] = createNewModel(difficulty);
          print('[LOAD] ✓ Modèle $difficulty créé par défaut');
        }
      }

      print('[LOAD] === Chargement terminé ===');
      return models;
    } catch (e, stackTrace) {
      print('[LOAD] ✗ Erreur chargement modèles IA: $e');
      print('[LOAD] Stack: $stackTrace');
      // Retourner les modèles par défaut en cas d'erreur
      return {
        'easy': createNewModel('easy'),
        'medium': createNewModel('medium'),
        'hard': createNewModel('hard'),
        'expert': createNewModel('expert'),
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

    // Entraîner le modèle avec un nombre d'epochs minimal pour performance
    // (1 epoch uniquement pour éviter les lenteurs)
    if (trainingData.isNotEmpty) {
      model.trainEpochs(trainingData, 1);
    }

    return model;
  }

  /// Entraîne un modèle adapté selon sa difficulté
  static Future<NeuralNetworkAI> trainModelWithDifficulty({
    required NeuralNetworkAI model,
    required List<GameStatistics> recentGames,
    required Map<String, dynamic> playerBehavior,
    required String difficulty,
  }) async {
    if (recentGames.isEmpty) return model;

    // Préparer les données d'entraînement
    final trainingData = <(List<double> input, List<double> target)>[];

    // Analyser chaque partie pour créer des exemples d'entraînement
    for (final game in recentGames) {
      // Créer une heatmap des positions touchées
      final heatmap = List<int>.filled(100, 0);

      for (final (row, col) in game.hitPositions) {
        heatmap[row * 10 + col] = 1;
      }

      for (final (row, col) in game.missPositions) {
        heatmap[row * 10 + col] = 2;
      }

      final input = heatmap.map((v) => (v / 2.0)).toList();
      final output = heatmap.map((v) => (v == 1 ? 1.0 : 0.0)).toList();

      trainingData.add((input, output));
    }

    // Adapter le nombre d'epochs selon la difficulté
    int epochs = 1;
    switch (difficulty) {
      case 'easy':
        epochs = 1; // Apprentissage minimal
        break;
      case 'medium':
        epochs = 2; // Apprentissage modéré
        break;
      case 'hard':
        epochs = 3; // Apprentissage important
        break;
      case 'expert':
        epochs = 4; // Apprentissage maximal
        break;
    }

    print('[TRAIN] $difficulty: ${recentGames.length} parties, $epochs epochs');

    // Entraîner le modèle
    if (trainingData.isNotEmpty) {
      model.trainEpochs(trainingData, epochs);
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
      print('[SAVE] === Sauvegarde du modèle ${model.difficulty} ===');
      print('[SAVE] PlayerId: $playerId');
      print('[SAVE] Entraînements: ${model.trainingIterations}');
      print('[SAVE] Learning rate: ${model.instanceLearningRate}');
      
      final modelData = {
        ...model.toJson(),
        'playerId': playerId,
        'difficulty': model.difficulty,
        'type': 'ai_model',
        'modelUniqueId': '${playerId}_${model.difficulty}',
        'savedAt': DateTime.now().toIso8601String(),
      };

      print('[SAVE] Données à sauvegarder: ${modelData.keys.toList()}');
      
      // Utiliser l'endpoint dédié pour les modèles IA
      await mongoService.saveAIModel(modelData);
      print('[SAVE] ✓ Modèle ${model.difficulty} sauvegardé (itérations: ${model.trainingIterations})');
      return true;
    } catch (e) {
      print('[SAVE] ✗ Erreur sauvegarde modèle: $e');
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
