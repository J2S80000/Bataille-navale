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
    print('GameScreen initState: player2IsAI=${currentGame.player2IsAI}');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCellTapped(int row, int col) {
    // Si c'est pas le tour du joueur 1, ne rien faire
    if (currentGame.currentTurnPlayerId != currentGame.player1.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pas ton tour!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final gameService = context.read<GameService>();

    try {
      final (result, updatedGame) = gameService.processMove(currentGame, row, col);

      setState(() {
        currentGame = updatedGame;
      });

      // Afficher le résultat du coup du joueur
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

      // Si c'est l'IA, elle joue automatiquement après une courte pause
      if (currentGame.player2IsAI && currentGame.currentTurnPlayerId == currentGame.player2.id) {
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            _playAIMove();
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _playAIMove() {
    try {
      final gameService = context.read<GameService>();
      
      // Générer un coup aléatoire pour l'IA
      int row = (DateTime.now().millisecondsSinceEpoch ~/ 13) % 10;
      int col = (DateTime.now().microsecond ~/ 7) % 10;
      
      print('🤖 IA joue à ($row, $col)');
      
      final (result, updatedGame) = gameService.processMove(currentGame, row, col);
      
      setState(() {
        currentGame = updatedGame;
      });

      // Afficher le résultat du coup de l'IA
      String message = '';
      switch (result) {
        case MoveResult.hit:
          message = '🤖 IA: Touché!';
          break;
        case MoveResult.miss:
          message = '🤖 IA: Manqué';
          break;
        case MoveResult.sunk:
          message = '🤖 IA: Coulé!';
          break;
        case MoveResult.invalid:
          message = '🤖 IA: Coup invalide';
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 2),
          backgroundColor: result == MoveResult.hit || result == MoveResult.sunk
              ? Colors.orange
              : Colors.blue,
        ),
      );
    } catch (e) {
      print('❌ Erreur coup IA: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur IA: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔧 GameScreen.build() starting...');
    try {
      return Scaffold(
        appBar: AppBar(
          title: Text('Bataille Navale vs ${currentGame.player2.name}'),
          elevation: 0,
          backgroundColor: Colors.blue.shade700,
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('📊 État du jeu:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Text('Joueur actuel: ${currentGame.currentPlayer.name}'),
                SizedBox(height: 8),
                Text('Ton plateau: ${currentGame.board1.ships.length} bateaux'),
                SizedBox(height: 8),
                Text('Plateau adversaire: ${currentGame.board2.ships.length} bateaux'),
                SizedBox(height: 8),
                Text('Statut: ${currentGame.status.toString().split('.').last}'),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: currentGame.status == GameStatus.playing
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Mode de jeu complet en développement')),
                          );
                        }
                      : null,
                  child: Text('Jouer'),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e, st) {
      print('❌ Erreur build: $e');
      print('Stack: $st');
      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Text('Erreur: $e\n\nStack:\n$st'),
          ),
        ),
      );
    }
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
