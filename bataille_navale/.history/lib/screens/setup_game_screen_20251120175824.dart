import 'package:flutter/material.dart';
import '../models/index.dart';
import 'index.dart';

/// Écran pour orchestrer le placement des bateaux pour les deux joueurs
class SetupGameScreen extends StatefulWidget {
  final String playerId;
  final String gameId;
  final Player player1;
  final Player player2;
  final bool isAI;

  const SetupGameScreen({
    Key? key,
    required this.playerId,
    required this.gameId,
    required this.player1,
    required this.player2,
    this.isAI = false,
  }) : super(key: key);

  @override
  State<SetupGameScreen> createState() => _SetupGameScreenState();
}

class _SetupGameScreenState extends State<SetupGameScreen> {
  late Board board1;
  late Board board2;
  int currentPlayerIndex = 1; // 1 ou 2

  @override
  void initState() {
    super.initState();
    board1 = null;
    board2 = null;
  }

  void _onPlayer1Placed(Board placedBoard) {
    print('✓ Joueur 1 a placé ses bateaux');
    setState(() {
      board1 = placedBoard;
      currentPlayerIndex = 2;
    });
  }

  void _onPlayer2Placed(Board placedBoard) {
    print('✓ Joueur 2 a placé ses bateaux');
    
    // Les deux joueurs ont placé leurs bateaux, on lance le jeu!
    final game = Game(
      id: widget.gameId,
      player1: widget.player1,
      player2: widget.player2,
      board1: board1!,
      board2: placedBoard,
      moves: [],
      currentTurnPlayerId: widget.player1.id,
      status: GameStatus.playing,
      createdAt: DateTime.now(),
      player2IsAI: widget.isAI,
    );

    print('✓ Jeu lancé avec board1 ships: ${game.board1.ships.length}, board2 ships: ${game.board2.ships.length}');

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GameScreen(game: game),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (board1 == null) {
      // Joueur 1 place ses bateaux
      return PlacementScreen(
        playerId: widget.player1.id,
        gameId: widget.gameId,
        onPlacementComplete: _onPlayer1Placed,
      );
    } else if (board2 == null) {
      // Joueur 2 place ses bateaux
      return Scaffold(
        appBar: AppBar(
          title: const Text('Placement - Joueur 2'),
          backgroundColor: Colors.blue.shade700,
        ),
        body: Stack(
          children: [
            PlacementScreen(
              playerId: widget.player2.id,
              gameId: widget.gameId,
              onPlacementComplete: _onPlayer2Placed,
            ),
            // Message overlay
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '👤 ${widget.player2.name} - À votre tour de placer vos bateaux!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Ne devrait pas arriver ici
    return SizedBox.shrink();
  }
}
