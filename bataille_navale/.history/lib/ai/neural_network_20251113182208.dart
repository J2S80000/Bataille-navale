import 'dart:math';
import '../models/index.dart';

/// Modèle de réseau de neurones pour l'IA de Bataille Navale
/// Prédit le placement des navires et la stratégie de tir
class NeuralNetworkModel {
  late List<List<double>> inputLayer;
  late List<List<double>> hiddenLayer1;
  late List<List<double>> hiddenLayer2;
  late List<double> outputLayer;

  final int gridSize = 100; // 10x10 board
  final int hiddenUnits1 = 64;
  final int hiddenUnits2 = 32;
  final int outputUnits = 100; // Probabilité pour chaque cellule

  late List<List<double>> weights1;
  late List<List<double>> weights2;
  late List<List<double>> weights3;
  late List<double> bias1;
  late List<double> bias2;
  late List<double> bias3;

  NeuralNetworkModel() {
    _initializeWeights();
  }

  /// Initialise les poids du réseau de neurones
  void _initializeWeights() {
    final random = Random();

    // Poids couche 1: input -> hidden1
    weights1 = List.generate(
      gridSize,
      (i) => List.generate(
        hiddenUnits1,
        (j) => (random.nextDouble() - 0.5) * 2,
      ),
    );

    // Poids couche 2: hidden1 -> hidden2
    weights2 = List.generate(
      hiddenUnits1,
      (i) => List.generate(
        hiddenUnits2,
        (j) => (random.nextDouble() - 0.5) * 2,
      ),
    );

    // Poids couche 3: hidden2 -> output
    weights3 = List.generate(
      hiddenUnits2,
      (i) => List.generate(
        outputUnits,
        (j) => (random.nextDouble() - 0.5) * 2,
      ),
    );

    // Biais
    bias1 = List.generate(hiddenUnits1, (i) => 0.1);
    bias2 = List.generate(hiddenUnits2, (i) => 0.1);
    bias3 = List.generate(outputUnits, (i) => 0.1);

    // Initialiser les couches
    inputLayer = List.generate(gridSize, (i) => [0.0]);
    hiddenLayer1 = List.generate(hiddenUnits1, (i) => [0.0]);
    hiddenLayer2 = List.generate(hiddenUnits2, (i) => [0.0]);
    outputLayer = List.generate(outputUnits, (i) => 0.0);
  }

  /// Fonction d'activation ReLU
  double _relu(double x) => max(0, x);

  /// Fonction d'activation Sigmoid
  double _sigmoid(double x) => 1 / (1 + exp(-x.clamp(-100, 100)));

  /// Fonction Softmax pour normaliser les probabilités
  List<double> _softmax(List<double> input) {
    final maxVal = input.reduce(max);
    final expValues = input.map((x) => exp((x - maxVal).clamp(-100, 100))).toList();
    final sum = expValues.reduce((a, b) => a + b);
    return expValues.map((x) => x / sum).toList();
  }

  /// Forward pass du réseau de neurones
  List<double> forward(List<double> input) {
    if (input.length != gridSize) {
      throw ArgumentError('Input size must be $gridSize');
    }

    inputLayer = input.map((x) => [x]).toList();

    // Couche 1: input -> hidden1
    for (int j = 0; j < hiddenUnits1; j++) {
      double sum = bias1[j];
      for (int i = 0; i < gridSize; i++) {
        sum += input[i] * weights1[i][j];
      }
      hiddenLayer1[j] = [_relu(sum)];
    }

    // Couche 2: hidden1 -> hidden2
    for (int j = 0; j < hiddenUnits2; j++) {
      double sum = bias2[j];
      for (int i = 0; i < hiddenUnits1; i++) {
        sum += hiddenLayer1[i][0] * weights2[i][j];
      }
      hiddenLayer2[j] = [_relu(sum)];
    }

    // Couche 3: hidden2 -> output
    for (int j = 0; j < outputUnits; j++) {
      double sum = bias3[j];
      for (int i = 0; i < hiddenUnits2; i++) {
        sum += hiddenLayer2[i][0] * weights3[i][j];
      }
      outputLayer[j] = _sigmoid(sum);
    }

    return _softmax(outputLayer);
  }

  /// Entraîne le réseau avec un exemple
  void train(
    List<double> input,
    List<double> targetOutput,
    double learningRate,
  ) {
    // Forward pass
    final prediction = forward(input);

    // Backpropagation simplifié
    final outputError =
        List.generate(outputUnits, (i) => targetOutput[i] - prediction[i]);

    // Mise à jour des poids couche 3
    for (int j = 0; j < outputUnits; j++) {
      for (int i = 0; i < hiddenUnits2; i++) {
        weights3[i][j] +=
            learningRate * outputError[j] * hiddenLayer2[i][0] * 0.1;
      }
      bias3[j] += learningRate * outputError[j];
    }
  }

  /// Sauvegarde le modèle entraîné
  Map<String, dynamic> toJson() {
    return {
      'weights1': weights1,
      'weights2': weights2,
      'weights3': weights3,
      'bias1': bias1,
      'bias2': bias2,
      'bias3': bias3,
    };
  }

  /// Charge un modèle entraîné
  void fromJson(Map<String, dynamic> json) {
    weights1 =
        List<List<double>>.from((json['weights1'] as List).map((row) {
      return List<double>.from(row as List);
    }));
    weights2 =
        List<List<double>>.from((json['weights2'] as List).map((row) {
      return List<double>.from(row as List);
    }));
    weights3 =
        List<List<double>>.from((json['weights3'] as List).map((row) {
      return List<double>.from(row as List);
    }));
    bias1 = List<double>.from(json['bias1'] as List);
    bias2 = List<double>.from(json['bias2'] as List);
    bias3 = List<double>.from(json['bias3'] as List);
  }
}
