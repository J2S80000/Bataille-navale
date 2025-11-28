import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/index.dart';

class GameScreen extends StatefulWidget {
  final Game game;

  const GameScreen({
    super.key,
    required this.game,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Game currentGame;
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    currentGame = widget.game;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCellTapped(int row, int col) {
    final gameService = context.read<GameService>();

    try {
      final (result, updatedGame) = gameService.processMove(currentGame, row, col);

      setState(() {
        currentGame = updatedGame;
      });

      // Afficher le résultat
      String message = '';
      switch (result) {
        case MoveResult.hit:
          message = '✓ Touché!';
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
          duration: Duration(seconds: 1),
          backgroundColor: result == MoveResult.hit || result == MoveResult.sunk
              ? Colors.green
              : Colors.red,
        ),
      );

      // Si c'est contre l'IA et que c'est maintenant le tour de l'IA, laisser l'IA jouer
      if (updatedGame.player2IsAI && updatedGame.currentTurnPlayerId == updatedGame.player2.id) {
        Future.delayed(Duration(milliseconds: 1000), () {
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
      // L'IA choisit une position aléatoire (à améliorer avec l'ML)
      int row = (DateTime.now().microsecond % 10);
      int col = (DateTime.now().millisecond % 10);
      
      // Assurez-vous que ce coup n'a pas déjà été fait
      bool validPosition = true;
      int attempts = 0;
      
      while (validPosition && attempts < 100) {
        final cell = currentGame.board1.getCell(row, col);
        if (cell.state == CellState.empty || cell.state == CellState.ship) {
          validPosition = false; // Position valide trouvée
          break;
        }
        row = (row + 1) % 10;
        col = (col + 1) % 10;
        attempts++;
      }

      if (validPosition) {
        print('IA tire sur ($row, $col)');
        final (result, updatedGame) = gameService.processMove(
          currentGame,
          row,
          col,
        );

        if (mounted) {
          setState(() {
            currentGame = updatedGame;
          });

          String aiMessage = '';
          switch (result) {
            case MoveResult.hit:
              aiMessage = '🤖 IA a touché!';
              break;
            case MoveResult.miss:
              aiMessage = '🤖 IA a manqué';
              break;
            case MoveResult.sunk:
              aiMessage = '🤖 IA a coulé un bateau!';
              break;
            case MoveResult.invalid:
              aiMessage = '🤖 Coup invalide';
              break;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(aiMessage),
              duration: Duration(seconds: 1),
              backgroundColor: result == MoveResult.hit || result == MoveResult.sunk
                  ? Colors.orange
                  : Colors.grey,
            ),
          );
        }
      }
    } catch (e) {
      print('Erreur coup IA: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bataille Navale'),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        actions: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                currentGame.currentPlayer.name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header avec infos de la partie
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPlayerInfo(currentGame.player1),
                Divider(height: 50),
                _buildPlayerInfo(currentGame.player2),
              ],
            ),
          ),
          // Plateaux
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
              children: [
                _buildBoardView(
                  'Mon Plateau',
                  currentGame.currentPlayerShipBoard,
                  showShips: true,
                  enabled: false,
                ),
                _buildBoardView(
                  'Plateau Adversaire',
                  currentGame.currentPlayerBoard,
                  showShips: false,
                  enabled: currentGame.status == GameStatus.playing,
                  onCellTap: _onCellTapped,
                ),
              ],
            ),
          ),
          // Indicateur page et boutons de navigation
          Container(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentPage == 0 ? Icons.radio_button_on : Icons.radio_button_off,
                      color: Colors.blue.shade700,
                    ),
                    SizedBox(width: 8),
                    Icon(
                      _currentPage == 1 ? Icons.radio_button_on : Icons.radio_button_off,
                      color: Colors.blue.shade700,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      icon: Icon(Icons.shield),
                      label: Text('Mes Bateaux'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentPage == 0 ? Colors.blue : Colors.grey,
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      icon: Icon(Icons.location_on),
                      label: Text('Attaquer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentPage == 1 ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Stats
          if (currentGame.status == GameStatus.finished)
            Padding(
              padding: EdgeInsets.all(16),
              child: _buildGameResultCard(),
            ),
        ],
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
    Board board,
    {
      required bool showShips,
      required bool enabled,
      Function(int, int)? onCellTap,
    }
  ) {
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
    Board board,
    {
      required bool showShips,
      required bool enabled,
      Function(int, int)? onCellTap,
    }
  ) {
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
    String? displayText;
    Color? textColor;

    switch (cell.state) {
      case CellState.empty:
        backgroundColor = Colors.blue.shade100;
        break;
      case CellState.hit:
        backgroundColor = Colors.red.shade300;
        displayText = '✕';
        textColor = Colors.red.shade700;
        break;
      case CellState.miss:
        backgroundColor = Colors.blue.shade200;
        displayText = '•';
        textColor = Colors.blue.shade700;
        break;
      case CellState.ship:
        backgroundColor = showShip ? Colors.grey.shade400 : Colors.blue.shade100;
        if (showShip) displayText = '⚓';
        textColor = showShip ? Colors.grey.shade800 : null;
        break;
      case CellState.sunk:
        backgroundColor = Colors.red.shade500;
        displayText = '✦';
        textColor = Colors.white;
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
          child: displayText != null
              ? Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 20,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildGameResultCard() {
    final winner = currentGame.winnerId == currentGame.player1.id
        ? currentGame.player1
        : currentGame.player2;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '✓ ${winner.name} a gagné!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
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
