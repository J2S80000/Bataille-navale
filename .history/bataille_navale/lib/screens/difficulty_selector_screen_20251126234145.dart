import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import 'index.dart';

class DifficultySelectorScreen extends StatefulWidget {
  final String playerId;
  final String playerName;

  const DifficultySelectorScreen({
    Key? key,
    required this.playerId,
    required this.playerName,
  }) : super(key: key);

  @override
  State<DifficultySelectorScreen> createState() =>
      _DifficultySelectorScreenState();
}

class _DifficultySelectorScreenState extends State<DifficultySelectorScreen> {
  final mongoService = MongoDBService();
  Map<String, dynamic>? modelsStats;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadModelsStats();
  }

  Future<void> _loadModelsStats() async {
    try {
      // Charger les statistiques des modèles IA depuis MongoDB
      final stats = await AIModelManager.loadUserModels(
        widget.playerId,
        mongoService,
      );

      if (mounted) {
        setState(() {
          // Convertir la liste de modèles en Map
          modelsStats = {};
          for (var model in stats.values) {
            modelsStats![model.difficulty] = {
              'trainingIterations': model.trainingIterations,
              'learningRate': model.instanceLearningRate,
            };
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print('[ERROR] Failed to load models: $e');
      if (mounted) {
        setState(() {
          error = 'Erreur lors du chargement des IA';
          isLoading = false;
        });
      }
    }
  }

  void _startGameWithDifficulty(String difficulty) {
    print('[GAME] Démarrage partie vs IA - Difficulté: $difficulty');

    final player1 = Player(
      id: widget.playerId,
      name: widget.playerName,
      email: 'player@example.com',
      createdAt: DateTime.now(),
    );
    final player2 = Player(
      id: 'ai_bot_$difficulty',
      name: _getDifficultyLabel(difficulty),
      email: 'ai@example.com',
      createdAt: DateTime.now(),
    );

    final game = Game(
      id: 'game_ai_${DateTime.now().millisecondsSinceEpoch}',
      player1: player1,
      player2: player2,
      board1: Board.empty(isVisible: true),
      board2: Board.empty(isVisible: false),
      moves: [],
      currentTurnPlayerId: widget.playerId,
      status: GameStatus.setup,
      createdAt: DateTime.now(),
      player2IsAI: true,
    );

    print('[INFO] Partie créée: ${game.id}');
    print('   Joueur 1: ${player1.name}');
    print('   Joueur 2 (IA): ${player2.name} - Difficulté: $difficulty');

    // Aller à l'écran de placement
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlacementScreen(
          playerId: widget.playerId,
          gameId: game.id,
          onPlacementComplete: (board) {
            print('[OK] Placement joueur terminé');
            print('   Navires sur plateau: ${board.ships.length}');

            // Générer le plateau de l'IA
            final gameService = GameService();
            final aiBoard = gameService.generateRandomShipPlacement();
            print('[IA] Plateau IA généré avec ${aiBoard.ships.length} navires');

            final updatedGame = game.copyWith(
              board1: board,
              board2: aiBoard,
              currentTurnPlayerId: widget.playerId,
              status: GameStatus.playing,
            );

            print('[GAME] Transition vers GameScreen...');
            print('   Board1: ${updatedGame.board1.ships.length} ships');
            print('   Board2: ${updatedGame.board2.ships.length} ships');

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => GameScreen(game: updatedGame),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'IA Facile';
      case 'medium':
        return 'IA Moyen';
      case 'hard':
        return 'IA Difficile';
      case 'expert':
        return 'IA Expert';
      default:
        return 'IA';
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.blue;
      case 'hard':
        return Colors.orange;
      case 'expert':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int _getTrainingCount(String difficulty) {
    if (modelsStats == null || !modelsStats!.containsKey(difficulty)) {
      return 0;
    }
    return modelsStats![difficulty]['trainingIterations'] ?? 0;
  }

  String _getStrengthBar(String difficulty, int trainingIterations) {
    // Afficher la force THÉORIQUE basée sur la difficulté configurée
    // Indépendante du nombre d'entraînements
    switch (difficulty) {
      case 'easy':
        // Easy: force de base faible
        if (trainingIterations == 0) {
          return '▓░░░░ (Débutant - Non entraîné)';
        } else if (trainingIterations < 10) {
          return '▓▓░░░ (Débutant - Apprenti)';
        } else if (trainingIterations < 25) {
          return '▓▓▓░░ (Débutant - Confirmé)';
        } else {
          return '▓▓▓▓░ (Débutant - Avancé)';
        }
        
      case 'medium':
        // Medium: force modérée
        if (trainingIterations == 0) {
          return '▓▓░░░ (Apprenti - Non entraîné)';
        } else if (trainingIterations < 20) {
          return '▓▓▓░░ (Apprenti - Confirmé)';
        } else if (trainingIterations < 50) {
          return '▓▓▓▓░ (Apprenti - Expert)';
        } else {
          return '▓▓▓▓▓ (Apprenti - Maître)';
        }
        
      case 'hard':
        // Hard: force élevée
        if (trainingIterations == 0) {
          return '▓▓▓░░ (Confirmé - Non entraîné)';
        } else if (trainingIterations < 30) {
          return '▓▓▓▓░ (Confirmé - Expert)';
        } else {
          return '▓▓▓▓▓ (Confirmé - Maître)';
        }
        
      case 'expert':
        // Expert: force maximale même à 0 entraînements
        if (trainingIterations == 0) {
          return '▓▓▓▓░ (Expert - Non entraîné)';
        } else {
          return '▓▓▓▓▓ (Expert - Maître)';
        }
        
      default:
        return '░░░░░ (Inconnu)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir la difficulté'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des IA...'),
                ],
              ),
            )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(error!),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadModelsStats,
                        child: Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.blue.shade50, Colors.blue.shade100],
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Sélectionnez votre adversaire IA',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        _buildDifficultyCard(
                          difficulty: 'easy',
                          label: 'Facile',
                          emoji: '⭐',
                          description: 'Parfait pour les débutants',
                          trainingCount: _getTrainingCount('easy'),
                        ),
                        SizedBox(height: 12),
                        _buildDifficultyCard(
                          difficulty: 'medium',
                          label: 'Moyen',
                          emoji: '⭐⭐',
                          description: 'Pour les joueurs confirmés',
                          trainingCount: _getTrainingCount('medium'),
                        ),
                        SizedBox(height: 12),
                        _buildDifficultyCard(
                          difficulty: 'hard',
                          label: 'Difficile',
                          emoji: '⭐⭐⭐',
                          description: 'Pour les experts',
                          trainingCount: _getTrainingCount('hard'),
                        ),
                        SizedBox(height: 12),
                        _buildDifficultyCard(
                          difficulty: 'expert',
                          label: 'Expert',
                          emoji: '⭐⭐⭐⭐⭐',
                          description: 'Le défi ultime',
                          trainingCount: _getTrainingCount('expert'),
                        ),
                        SizedBox(height: 24),
                        Card(
                          color: Colors.amber.shade50,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '💡 Conseil',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Plus l\'IA est entraînée, plus elle sera difficile. Les statistiques d\'entraînement'
                                  ' aident l\'IA à apprendre vos stratégies et à s\'adapter.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDifficultyCard({
    required String difficulty,
    required String label,
    required String emoji,
    required String description,
    required int trainingCount,
  }) {
    final color = _getDifficultyColor(difficulty);
    final strengthBar = _getStrengthBar(trainingCount);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _startGameWithDifficulty(difficulty),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: color),
                ],
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Force:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          strengthBar,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '🎯 Entraînements: $trainingCount',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
