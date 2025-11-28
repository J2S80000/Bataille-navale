import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/index.dart';

class GameScreenV2 extends StatefulWidget {
  final Game game;

  const GameScreenV2({
    super.key,
    required this.game,
  });

  @override
  State<GameScreenV2> createState() => _GameScreenV2State();
}

class _GameScreenV2State extends State<GameScreenV2> {
  late Game currentGame;

  @override
  void initState() {
    super.initState();
    currentGame = widget.game;
    print('✓ GameScreenV2 initState: player2IsAI=${currentGame.player2IsAI}');
  }

  void _onCellTapped(int row, int col) {
    print('Cell tapped: ($row, $col)');
    final gameService = context.read<GameService>();

    try {
      // Vérifier que c'est au joueur 1 de jouer
      if (currentGame.currentTurnPlayerId != currentGame.player1.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pas ton tour')),
        );
        return;
      }

      // Traiter le coup
      final (result, updatedGame) = gameService.processMove(currentGame, row, col);

      setState(() {
        currentGame = updatedGame;
      });

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
        SnackBar(content: Text(message), duration: Duration(seconds: 1)),
      );

      // Si l'IA joue, elle joue après 1 seconde
      if (currentGame.player2IsAI && currentGame.currentTurnPlayerId == currentGame.player2.id) {
        Future.delayed(Duration(seconds: 1), _playAIMove);
      }
    } catch (e) {
      print('Erreur: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _playAIMove() {
    try {
      final gameService = context.read<GameService>();
      
      // Coup aléatoire
      int row = DateTime.now().millisecond % 10;
      int col = DateTime.now().microsecond % 10;
      
      final (result, updatedGame) = gameService.processMove(currentGame, row, col);

      setState(() {
        currentGame = updatedGame;
      });

      String message = '🤖 IA joue: ';
      switch (result) {
        case MoveResult.hit:
          message += 'Touché!';
          break;
        case MoveResult.miss:
          message += 'Manqué';
          break;
        case MoveResult.sunk:
          message += 'Coulé!';
          break;
        case MoveResult.invalid:
          message += 'Coup invalide';
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: Duration(seconds: 1)),
      );
    } catch (e) {
      print('Erreur IA: $e');
    }
  }

  Widget _buildCell(int row, int col, bool isOpponentBoard) {
    final board = isOpponentBoard ? currentGame.board2 : currentGame.board1;
    final cell = board.getCell(row, col);

    Color color = Colors.grey.shade200;
    String symbol = '';

    switch (cell.state) {
      case CellState.empty:
        color = Colors.blue.shade100;
        break;
      case CellState.ship:
        color = Colors.blue.shade300;
        symbol = '⚓';
        break;
      case CellState.hit:
        color = Colors.red;
        symbol = '✕';
        break;
      case CellState.miss:
        color = Colors.blue.shade200;
        symbol = '•';
        break;
      case CellState.sunk:
        color = Colors.red.shade700;
        symbol = '✦';
        break;
    }

    return GestureDetector(
      onTap: isOpponentBoard ? () => _onCellTapped(row, col) : null,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.grey.shade400, width: 0.5),
        ),
        child: Center(
          child: Text(
            symbol,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildBoard(String title, bool isOpponentBoard) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 10,
            childAspectRatio: 1,
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
          ),
          itemCount: 100,
          itemBuilder: (context, index) {
            int row = index ~/ 10;
            int col = index % 10;
            return _buildCell(row, col, isOpponentBoard);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bataille Navale'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'À ${currentGame.currentPlayer.name}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 380,
                        child: _buildBoard('Mon Plateau', false),
                      ),
                      SizedBox(width: 32),
                      SizedBox(
                        width: 380,
                        child: _buildBoard('Plateau Adversaire', true),
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
}
