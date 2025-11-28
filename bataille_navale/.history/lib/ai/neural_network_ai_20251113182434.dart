import 'dart:math';
import 'neural_network.dart';
import 'player_profile_analyzer.dart';
import '../models/index.dart';

/// IA améliorée avec réseau de neurones pour Bataille Navale
class NeuralNetworkBattleshipAI {
  final NeuralNetworkAI neuralNetwork;
  final List<GameStatistics> playerHistory;
  late List<List<double>> heatmap;
  late List<List<double>> shipPredictions;
  late Map<String, dynamic> playerProfile;

  static const int BOARD_SIZE = 10;

  NeuralNetworkBattleshipAI({
    required this.playerHistory,
  }) : neuralNetwork = NeuralNetworkAI() {
    _analyzePlayer();
  }

  /// Analyse le profil du joueur adverse
  void _analyzePlayer() {
    heatmap = PlayerProfileAnalyzer.analyzeHotZones(playerHistory);
    shipPredictions = PlayerProfileAnalyzer.predictShipPlacement(playerHistory);
    playerProfile = PlayerProfileAnalyzer.analyzeAttackPattern(playerHistory);
  }

  /// Entraîne le NN avec l'historique des parties
  void trainNetwork() {
    for (final game in playerHistory) {
      // Créer un vecteur d'entrée basé sur l'état du jeu
      final input = List<double>.filled(100, 0.0);

      // Marquer les hits et misses
      for (final (row, col) in game.hitPositions) {
        if (row >= 0 && row < BOARD_SIZE && col >= 0 && col < BOARD_SIZE) {
          input[row * BOARD_SIZE + col] = 1.0; // Hit
        }
      }

      for (final (row, col) in game.missPositions) {
        if (row >= 0 && row < BOARD_SIZE && col >= 0 && col < BOARD_SIZE) {
          input[row * BOARD_SIZE + col] = 0.5; // Miss
        }
      }

      // Créer le vecteur cible (zones préférées)
      final target = List<double>.filled(100, 0.0);
      for (int i = 0; i < BOARD_SIZE; i++) {
        for (int j = 0; j < BOARD_SIZE; j++) {
          target[i * BOARD_SIZE + j] = heatmap[i][j];
        }
      }

      // Entraîner le réseau
      neuralNetwork.train(input, target);
    }
  }

  /// Prédit le meilleur prochain coup
  int predictNextMove(List<List<int>> currentBoard) {
    // Convertir le board en vecteur
    final input = List<double>.filled(100, 0.0);
    for (int i = 0; i < BOARD_SIZE; i++) {
      for (int j = 0; j < BOARD_SIZE; j++) {
        input[i * BOARD_SIZE + j] = currentBoard[i][j].toDouble();
      }
    }

    // Prédiction du NN
    final nnPrediction = neuralNetwork.forward(input);

    // Combiner avec les heatmaps
    final combined = List<double>.filled(100, 0.0);
    for (int i = 0; i < 100; i++) {
      combined[i] =
          (nnPrediction[i] * 0.4 +
              heatmap[i ~/ BOARD_SIZE][i % BOARD_SIZE] * 0.3 +
              shipPredictions[i ~/ BOARD_SIZE][i % BOARD_SIZE] * 0.3) /
          3;
    }

    // Trouver la cellule avec la meilleure prédiction (non ciblée)
    int bestMove = -1;
    double bestScore = -1.0;

    for (int i = 0; i < BOARD_SIZE; i++) {
      for (int j = 0; j < BOARD_SIZE; j++) {
        final cellIndex = i * BOARD_SIZE + j;

        // Éviter les cellules déjà ciblées
        if (currentBoard[i][j] == 0) {
          if (combined[cellIndex] > bestScore) {
            bestScore = combined[cellIndex];
            bestMove = cellIndex;
          }
        }
      }
    }

    return bestMove >= 0 ? bestMove : _getRandomMove(currentBoard);
  }

  /// Récupère un coup aléatoire (fallback)
  int _getRandomMove(List<List<int>> currentBoard) {
    final availableMoves = <int>[];

    for (int i = 0; i < BOARD_SIZE; i++) {
      for (int j = 0; j < BOARD_SIZE; j++) {
        if (currentBoard[i][j] == 0) {
          availableMoves.add(i * BOARD_SIZE + j);
        }
      }
    }

    if (availableMoves.isEmpty) return -1;
    return availableMoves[Random().nextInt(availableMoves.length)];
  }

  /// Prédit le style du joueur adverse
  String predictOpponentStyle() {
    return playerProfile['style'] ?? 'balanced';
  }

  /// Évalue la compétence du joueur adverse
  double getOpponentSkillRating() {
    return PlayerProfileAnalyzer.calculateSkillRating(playerHistory);
  }

  /// Génère une stratégie adaptée au joueur
  Map<String, dynamic> generateAdaptiveStrategy() {
    final style = predictOpponentStyle();
    final skillRating = getOpponentSkillRating();
    final progression = PlayerProfileAnalyzer.analyzeProgression(playerHistory);

    return {
      'style': style,
      'skillRating': skillRating,
      'progression': progression,
      'recommendations': _getRecommendations(style, skillRating),
    };
  }

  /// Recommandations tactiques basées sur le profil
  List<String> _getRecommendations(String style, double skillRating) {
    final recommendations = <String>[];

    if (style == 'aggressive') {
      recommendations.add('Adopter une défense concentrée');
      recommendations.add('Placer les navires au centre');
    } else if (style == 'defensive') {
      recommendations.add('Attaquer les flancs');
      recommendations.add('Cibler les zones imprévisibles');
    } else if (style == 'random') {
      recommendations.add('Chercher des patterns cachés');
      recommendations.add('Adapter stratégiquement');
    }

    if (skillRating > 0.8) {
      recommendations.add('⚠️ Adversaire très compétent - augmenter la vigilance');
    } else if (skillRating < 0.3) {
      recommendations.add('✓ Adversaire plus faible - exploiter les faiblesses');
    }

    return recommendations;
  }

  /// Génère des parties d'entraînement réalistes
  List<Move> generateRealisticMoves(int moveCount) {
    final moves = <Move>[];
    final board = List.generate(BOARD_SIZE, (_) => List.filled(BOARD_SIZE, 0));

    for (int i = 0; i < moveCount; i++) {
      final moveIndex = predictNextMove(board);
      if (moveIndex < 0) break;

      final row = moveIndex ~/ BOARD_SIZE;
      final col = moveIndex % BOARD_SIZE;

      moves.add(Move(
        id: 'move_${DateTime.now().millisecondsSinceEpoch}_$i',
        row: row,
        col: col,
        result: MoveResult.miss,
        playerId: 'ai_player',
        timestamp: DateTime.now(),
      ));

      // Mettre à jour le board
      board[row][col] = 1;
    }

    return moves;
  }
}
