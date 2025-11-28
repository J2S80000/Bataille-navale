import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/index.dart';
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
  late Board? board1;
  late Board? board2;
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

    // L'IA place ses bateaux automatiquement
    if (widget.isAI) {
      _placeAIShips();
    }
  }

  void _placeAIShips() {
    print('🤖 L\'IA place ses bateaux...');
    try {
      final gameService = GameService();
      Board aiBoard = Board.empty(isVisible: false);

      // Placer les bateaux de l'IA aléatoirement mais intelligemment
      for (final shipType in ShipType.values) {
        bool placed = false;
        int attempts = 0;
        const maxAttempts = 200;

        while (!placed && attempts < maxAttempts) {
          final row = (DateTime.now().microsecond + attempts) % 10;
          final col = (DateTime.now().millisecond + attempts) % 10;
          final isHorizontal = (attempts % 2 == 0);

          if (gameService.canPlaceShip(aiBoard, row, col, shipType, isHorizontal)) {
            aiBoard = gameService.placeShip(aiBoard, row, col, shipType, isHorizontal);
            placed = true;
            print('✓ IA a placé ${shipType.displayName}');
          }
          attempts++;
        }

        if (!placed) {
          print('⚠ L\'IA n\'a pas pu placer ${shipType.displayName}');
        }
      }

      print('✓ L\'IA a placé ${aiBoard.ships.length} bateaux');

      // Démarrer le jeu
      _startGame(aiBoard);
    } catch (e) {
      print('❌ Erreur placement IA: $e');
    }
  }

  void _startGame(Board board2) {
    try {
      final game = Game(
        id: widget.gameId,
        player1: widget.player1,
        player2: widget.player2,
        board1: board1 ?? Board.empty(),
        board2: board2,
        moves: [],
        currentTurnPlayerId: widget.player1.id,
        status: GameStatus.playing,
        createdAt: DateTime.now(),
        player2IsAI: widget.isAI,
      );

      print('✓ Jeu lancé! board1 ships: ${game.board1.ships.length}, board2 ships: ${game.board2.ships.length}');

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => GameScreen(game: game),
        ),
      );
    } catch (e) {
      print('❌ Erreur lancement jeu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _onPlayer2Placed(Board placedBoard) {
    print('✓ Joueur 2 a placé ses bateaux');
    
    // Les deux joueurs humains ont placé leurs bateaux, on lance le jeu!
    _startGame(placedBoard);
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
    } else if (board2 == null && !widget.isAI) {
      // Joueur 2 place ses bateaux (seulement en mode local, pas IA)
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
    } else if (widget.isAI && board2 == null) {
      // L'IA place ses bateaux - afficher un écran de chargement
      return Scaffold(
        appBar: AppBar(
          title: const Text('Préparation'),
          backgroundColor: Colors.blue.shade700,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                ),
              ),
              SizedBox(height: 24),
              Text(
                '🤖 L\'IA place ses bateaux...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Veuillez patienter',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Ne devrait pas arriver ici
    return SizedBox.shrink();
  }
}
