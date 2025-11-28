import 'dart:math';

/// Réseau de neurones simple pour prédire le placement des navires et la stratégie de tir
class NeuralNetworkAI {
  // Métadonnées du modèle
  late String modelId;
  late String difficulty; // 'easy', 'medium', 'hard', 'expert'
  late int trainingIterations;
  late double instanceLearningRate;

  // Architecture du réseau
  late List<List<double>> inputHiddenWeights;
  late List<List<double>> hiddenOutputWeights;
  late List<double> hiddenBias;
  late List<double> outputBias;

  // Paramètres d'apprentissage statiques
  static const double learningRate = 0.01;
  static const int inputSize = 100; // 10x10 grille
  static const int hiddenSize = 64;
  static const int outputSize = 100; // Prédiction pour chaque cellule

  NeuralNetworkAI({
    String? modelId,
    this.difficulty = 'medium',
    this.trainingIterations = 0,
    this.instanceLearningRate = 0.01,
  }) {
    this.modelId = modelId ?? 'model_${DateTime.now().millisecondsSinceEpoch}';
    _initializeWeights();
  }

  /// Initialise les poids avec des valeurs aléatoires
  void _initializeWeights() {
    final random = Random();
    
    inputHiddenWeights = List.generate(
      inputSize,
      (_) => List.generate(
        hiddenSize,
        (_) => (random.nextDouble() - 0.5) * 2,
      ),
    );

    hiddenOutputWeights = List.generate(
      hiddenSize,
      (_) => List.generate(
        outputSize,
        (_) => (random.nextDouble() - 0.5) * 2,
      ),
    );

    hiddenBias = List.generate(hiddenSize, (_) => 0.0);
    outputBias = List.generate(outputSize, (_) => 0.0);
  }

  /// Fonction d'activation ReLU
  static double relu(double x) => max(0, x);

  /// Dérivée de ReLU
  static double reluDerivative(double x) => x > 0 ? 1.0 : 0.0;

  /// Fonction sigmoid
  static double sigmoid(double x) => 1.0 / (1.0 + exp(-x));

  /// Forward pass du réseau
  List<double> forward(List<double> input) {
    // Couche cachée
    final hidden = List<double>.filled(hiddenSize, 0.0);
    for (int i = 0; i < hiddenSize; i++) {
      double sum = hiddenBias[i];
      for (int j = 0; j < inputSize; j++) {
        sum += input[j] * inputHiddenWeights[j][i];
      }
      hidden[i] = relu(sum);
    }

    // Couche de sortie
    final output = List<double>.filled(outputSize, 0.0);
    for (int i = 0; i < outputSize; i++) {
      double sum = outputBias[i];
      for (int j = 0; j < hiddenSize; j++) {
        sum += hidden[j] * hiddenOutputWeights[j][i];
      }
      output[i] = sigmoid(sum); // Probabilité entre 0 et 1
    }

    return output;
  }

  /// Entraînement du réseau avec backpropagation
  void train(List<double> input, List<double> targetOutput) {
    // Forward pass
    final hidden = List<double>.filled(hiddenSize, 0.0);
    final hiddenPre = List<double>.filled(hiddenSize, 0.0);

    for (int i = 0; i < hiddenSize; i++) {
      double sum = hiddenBias[i];
      for (int j = 0; j < inputSize; j++) {
        sum += input[j] * inputHiddenWeights[j][i];
      }
      hiddenPre[i] = sum;
      hidden[i] = relu(sum);
    }

    final output = List<double>.filled(outputSize, 0.0);
    final outputPre = List<double>.filled(outputSize, 0.0);

    for (int i = 0; i < outputSize; i++) {
      double sum = outputBias[i];
      for (int j = 0; j < hiddenSize; j++) {
        sum += hidden[j] * hiddenOutputWeights[j][i];
      }
      outputPre[i] = sum;
      output[i] = sigmoid(sum);
    }

    // Backpropagation - Couche de sortie
    final outputDeltas = List<double>.filled(outputSize, 0.0);
    for (int i = 0; i < outputSize; i++) {
      final error = targetOutput[i] - output[i];
      outputDeltas[i] = error * output[i] * (1 - output[i]); // Dérivée sigmoid
    }

    // Backpropagation - Couche cachée
    final hiddenDeltas = List<double>.filled(hiddenSize, 0.0);
    for (int i = 0; i < hiddenSize; i++) {
      double sum = 0.0;
      for (int j = 0; j < outputSize; j++) {
        sum += outputDeltas[j] * hiddenOutputWeights[i][j];
      }
      hiddenDeltas[i] = sum * reluDerivative(hiddenPre[i]);
    }

    // Mise à jour des poids - Couche de sortie
    for (int i = 0; i < hiddenSize; i++) {
      for (int j = 0; j < outputSize; j++) {
        hiddenOutputWeights[i][j] +=
            instanceLearningRate * outputDeltas[j] * hidden[i];
      }
    }

    // Mise à jour des poids - Couche cachée
    for (int i = 0; i < inputSize; i++) {
      for (int j = 0; j < hiddenSize; j++) {
        inputHiddenWeights[i][j] +=
            instanceLearningRate * hiddenDeltas[j] * input[i];
      }
    }

    // Mise à jour des biais
    for (int i = 0; i < outputSize; i++) {
      outputBias[i] += instanceLearningRate * outputDeltas[i];
    }

    for (int i = 0; i < hiddenSize; i++) {
      hiddenBias[i] += instanceLearningRate * hiddenDeltas[i];
    }
  }

  /// Entraîne le modèle sur plusieurs epochs
  void trainEpochs(List<(List<double> input, List<double> target)> trainingData, int epochs) {
    for (int epoch = 0; epoch < epochs; epoch++) {
      for (final (input, target) in trainingData) {
        train(input, target);
      }
      trainingIterations++;
    }
  }

  /// Convertit la grille 2D en vecteur 1D
  static List<double> gridToVector(List<List<int>> grid) {
    final vector = <double>[];
    for (final row in grid) {
      for (final cell in row) {
        vector.add(cell.toDouble());
      }
    }
    return vector;
  }

  /// Convertit un vecteur 1D en grille 2D
  static List<List<int>> vectorToGrid(List<double> vector, int size) {
    final grid = <List<int>>[];
    for (int i = 0; i < size; i++) {
      final row = <int>[];
      for (int j = 0; j < size; j++) {
        row.add(vector[i * size + j].round());
      }
      grid.add(row);
    }
    return grid;
  }

  /// Sauvegarde les poids du réseau
  Map<String, dynamic> toJson() {
    return {
      'inputHiddenWeights': inputHiddenWeights,
      'hiddenOutputWeights': hiddenOutputWeights,
      'hiddenBias': hiddenBias,
      'outputBias': outputBias,
    };
  }

  /// Charge les poids du réseau
  void fromJson(Map<String, dynamic> json) {
    inputHiddenWeights = (json['inputHiddenWeights'] as List)
        .map((row) => (row as List).map((x) => (x as num).toDouble()).toList())
        .toList();
    hiddenOutputWeights = (json['hiddenOutputWeights'] as List)
        .map((row) => (row as List).map((x) => (x as num).toDouble()).toList())
        .toList();
    hiddenBias = (json['hiddenBias'] as List)
        .map((x) => (x as num).toDouble())
        .toList();
    outputBias = (json['outputBias'] as List)
        .map((x) => (x as num).toDouble())
        .toList();
  }
}
