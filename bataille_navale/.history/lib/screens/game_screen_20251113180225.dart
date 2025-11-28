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
          duration: Duration(seconds: 1),
          backgroundColor: result == MoveResult.hit || result == MoveResult.sunk
              ? Colors.green
              : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
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
          // Indicateur page
          Container(
            padding: EdgeInsets.all(8),
            child: Row(
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
    },
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
        if (showShip) iconData = Icons.directions_boat;
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

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '🏆 ${winner.name} a gagné!',
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
