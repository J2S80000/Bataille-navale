import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../ai/genetic_algorithm.dart';
import '../ai/predictor.dart';
import '../ai/neural_network.dart';

class GameScreen extends StatefulWidget {
  final Game game;

  const GameScreen({
    Key? key,
    required this.game,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Game currentGame;
  NeuralNetworkAI? aiModel;
  String? aiDifficulty;
  bool isLoadingModel = false;

  @override
  void initState() {
    super.initState();
    print('[GameScreen] initState - game loaded');
    print('   Player1: ${widget.game.player1.name}');
    print('   Player2: ${widget.game.player2.name}');
    print('   Board1 ships: ${widget.game.board1.ships.length}');
    print('   Board2 ships: ${widget.game.board2.ships.length}');
    print('   Status: ${widget.game.status}');
    currentGame = widget.game;
    
    // Charger le modèle IA si nécessaire
    if (currentGame.player2IsAI) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAIModel();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadAIModel() async {
    // Extraire la difficulté du nom du joueur
    // Noms possibles: "IA Facile", "IA Moyen", "IA Difficile", "IA Expert"
    final aiName = currentGame.player2.name.toLowerCase();
    
    if (aiName.contains('expert')) {
      aiDifficulty = 'expert';
    } else if (aiName.contains('difficile')) {
      aiDifficulty = 'hard';
    } else if (aiName.contains('moyen')) {
      aiDifficulty = 'medium';
    } else if (aiName.contains('facile')) {
      aiDifficulty = 'easy';
    }

    if (aiDifficulty == null) {
      print('[ERREUR] Impossible de déterminer la difficulté IA');
      return;
    }

    print('[AI] Chargement du modèle $aiDifficulty');

    if (mounted) {
      setState(() => isLoadingModel = true);
    }

    try {
      // Charger les modèles IA
      final mongoService = MongoDBService();
      final models = await AIModelManager.loadUserModels(
        currentGame.player1.id,
        mongoService,
      );

      // Sélectionner le modèle correspondant à la difficulté
      if (models.containsKey(aiDifficulty)) {
        if (mounted) {
          setState(() {
            aiModel = models[aiDifficulty];
            isLoadingModel = false;
          });
          print('[AI] Modèle chargé: $aiDifficulty avec ${aiModel!.trainingIterations} entraînements');
        }
      } else {
        print('[ERREUR] Modèle $aiDifficulty non trouvé');
        if (mounted) {
          setState(() => isLoadingModel = false);
        }
      }
    } catch (e) {
      print('[ERREUR] Erreur lors du chargement du modèle: $e');
      if (mounted) {
        setState(() => isLoadingModel = false);
      }
    }
  }

  void _onCellTapped(int row, int col) {
    final gameService = GameService();

    try {
      final (result, updatedGame) = gameService.processMove(currentGame, row, col);

      setState(() {
        currentGame = updatedGame;
      });

      // Afficher le résultat
      String message = '';
      switch (result) {
        case MoveResult.hit:
          message = '🎯 Touché!';
          break;
        case MoveResult.miss:
          message = '❌ Manqué';
          break;
        case MoveResult.sunk:
          message = '💥 Coulé!';
          break;
        case MoveResult.invalid:
          message = '⚠️ Coup invalide';
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(milliseconds: 500),
          backgroundColor: result == MoveResult.hit || result == MoveResult.sunk
              ? Colors.green
              : Colors.red,
        ),
      );

      // Si l'IA doit jouer maintenant
      if (updatedGame.player2IsAI && updatedGame.status == GameStatus.playing && updatedGame.isPlayer2Turn) {
        Future.delayed(Duration(milliseconds: 400), () {
          _playAIMove(gameService);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _playAIMove(GameService gameService) {
    try {
      if (!mounted) return;

      int row = 0;
      int col = 0;

      // Utiliser le modèle neural si disponible
      if (aiModel != null) {
        // Préparer l'input du board pour le neural network
        // Convertir le board en array de 100 éléments (10x10)
        final input = List<double>.filled(100, 0.0);
        
        for (int i = 0; i < 10; i++) {
          for (int j = 0; j < 10; j++) {
            int idx = i * 10 + j;
            final cell = currentGame.board1.grid[i][j];
            
            // Encoder l'état de la cellule
            if (cell.state == CellState.hit) {
              input[idx] = 1.0; // Hit (touchée)
            } else if (cell.state == CellState.miss) {
              input[idx] = 0.5; // Miss (manquée)
            } else if (cell.state == CellState.sunk) {
              input[idx] = 0.8; // Sunk (coulée)
            } else {
              input[idx] = 0.0; // Unknown/Empty
            }
          }
        }

        // Prédire les meilleurs coups
        final output = aiModel!.forward(input);
        
        // Trouver les cellules non jouées avec les plus hautes probabilités
        double maxProb = -1;
        for (int i = 0; i < 10; i++) {
          for (int j = 0; j < 10; j++) {
            int idx = i * 10 + j;
            final cell = currentGame.board1.grid[i][j];
            
            // Ne jouer que sur les cellules non encore jouées (empty ou ship)
            if ((cell.state == CellState.empty || cell.state == CellState.ship) && output[idx] > maxProb) {
              maxProb = output[idx];
              row = i;
              col = j;
            }
          }
        }
        
        print('[IA] Modèle ${aiDifficulty!} prédit: ($row, $col) avec probabilité $maxProb');
      } else {
        // Fallback: utiliser la stratégie par défaut si le modèle n'est pas chargé
        final defaultStrategy = AIStrategy(
          id: 'default-ai',
          weights: [0.2, 0.3, 0.2, 0.2, 0.1],
          fitness: 0.0,
        );

        final predictor = MovePredictor(
          strategy: defaultStrategy,
          trainingData: [],
        );

        final aiMoves = currentGame.moves.where((m) => m.playerId == currentGame.player2.id).toList();
        (row, col) = predictor.predictNextMove(currentGame.board1, aiMoves);
        
        print('[IA] Stratégie par défaut: ($row, $col)');
      }

      print('[IA] Joue coup: ($row, $col)');

      // Faire le coup
      final (result, updatedGame) = gameService.processMove(currentGame, row, col);

      if (mounted) {
        setState(() {
          currentGame = updatedGame;
        });

        // Afficher le coup de l'IA
        String message = '';
        switch (result) {
          case MoveResult.hit:
            message = 'IA: Touche!';
            break;
          case MoveResult.miss:
            message = 'IA: Manque';
            break;
          case MoveResult.sunk:
            message = 'IA: Coule!';
            break;
          case MoveResult.invalid:
            message = 'IA: Coup invalide';
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: Duration(milliseconds: 500),
            backgroundColor: result == MoveResult.hit || result == MoveResult.sunk
                ? Colors.green
                : Colors.red,
          ),
        );
      }
    } catch (e) {
      print('[ERREUR] IA: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur IA: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[GameScreen] build() called');
    
    String appBarTitle = 'Bataille Navale - ${currentGame.currentPlayer.name} vs ${currentGame.opponent.name}';
    if (currentGame.player2IsAI && aiModel != null && aiDifficulty != null) {
      appBarTitle = 'vs ${aiDifficulty!.toUpperCase()} (${aiModel!.trainingIterations} entraînements)';
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header avec infos de la partie
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPlayerInfo(currentGame.player1),
                    VerticalDivider(),
                    _buildPlayerInfo(currentGame.player2),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Mon plateau (affichage seul)
            _buildBoardView(
              'Mon Plateau (${currentGame.currentPlayerShipBoard.ships.length} navires)',
              currentGame.currentPlayerShipBoard,
              showShips: true,
              enabled: false,
            ),
            SizedBox(height: 24),
            
            // Plateau adversaire (jouable)
            Text(
              'Plateau Adversaire (Cliquez pour tirer)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildBoardView(
              'Plateau Adversaire',
              currentGame.currentPlayerBoard,
              showShips: false,
              enabled: currentGame.status == GameStatus.playing,
              onCellTap: _onCellTapped,
            ),
            SizedBox(height: 24),
            
            // Résultat si jeu terminé
            if (currentGame.status == GameStatus.finished)
              _buildGameResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerInfo(Player player) {
    return Column(
      children: [
        Text(
          player.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 4),
        Text('${player.wins}W ${player.losses}L'),
      ],
    );
  }

  Widget _buildBoardView(
    String title,
    Board board, {
    required bool showShips,
    required bool enabled,
    Function(int, int)? onCellTap,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildGridView(
            board,
            showShips: showShips,
            enabled: enabled,
            onCellTap: onCellTap,
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(
    Board board, {
    required bool showShips,
    required bool enabled,
    Function(int, int)? onCellTap,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        childAspectRatio: 1,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: 100,
      itemBuilder: (context, index) {
        final row = index ~/ 10;
        final col = index % 10;
        final cell = board.getCell(row, col);

        return _buildCellWidget(
          cell: cell,
          showShip: showShips && board.hasShip(row, col),
          enabled: enabled,
          onTap: onCellTap != null ? () => onCellTap(row, col) : null,
        );
      },
    );
  }

  Widget _buildCellWidget({
    required Cell cell,
    required bool showShip,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    Color backgroundColor = Colors.blue.shade100;
    IconData? iconData;
    Color? iconColor;

    switch (cell.state) {
      case CellState.empty:
        backgroundColor = Colors.blue.shade100;
        break;
      case CellState.hit:
        backgroundColor = Colors.red.shade300;
        iconData = Icons.close;
        iconColor = Colors.red;
        break;
      case CellState.miss:
        backgroundColor = Colors.blue.shade200;
        iconData = Icons.fiber_manual_record;
        iconColor = Colors.blue;
        break;
      case CellState.ship:
        backgroundColor = showShip ? Colors.grey : Colors.blue.shade100;
        if (showShip) iconData = Icons.waves;
        break;
      case CellState.sunk:
        backgroundColor = Colors.red.shade500;
        iconData = Icons.warning;
        iconColor = Colors.white;
        break;
    }

    return GestureDetector(
      onTap: enabled && onTap != null ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: Colors.blue.shade300, width: 0.5),
        ),
        child: Center(
          child: iconData != null
              ? Icon(iconData, size: 16, color: iconColor)
              : null,
        ),
      ),
    );
  }

  Widget _buildGameResultCard() {
    final winner = currentGame.winnerId == currentGame.player1.id
        ? currentGame.player1
        : currentGame.player2;
    
    final isPlayerWon = winner.id == 'player_123'; // ID du joueur principal
    final resultMessage = isPlayerWon ? 'Vous avez gagne!' : '${winner.name} a gagne!';

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '🏆 $resultMessage',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isPlayerWon ? Colors.green : Colors.orange,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Retour'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Nouvelle partie
                  },
                  child: Text('Nouvelle Partie'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
