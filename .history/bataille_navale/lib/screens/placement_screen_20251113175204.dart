import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/index.dart';

class PlacementScreen extends StatefulWidget {
  final String playerId;
  final String? gameId;
  final Function(Board) onPlacementComplete;

  const PlacementScreen({
    Key? key,
    required this.playerId,
    this.gameId,
    required this.onPlacementComplete,
  }) : super(key: key);

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends State<PlacementScreen> {
  late Board board;
  Ship? selectedShip;
  bool isHorizontal = true;
  List<InitialPlacementStrategy>? recommendations;
  int? recommendedStrategyIndex;

  @override
  void initState() {
    super.initState();
    board = Board.empty();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final firebase = context.read<FirebaseService>();
    final analytics = context.read<AdvancedAnalyticsService>();

    try {
      final opponentStats = await _loadOpponentStats();

      // Générer 3 stratégies recommandées
      final strategies = <InitialPlacementStrategy>[];
      for (final stratType in ['defensive', 'balanced', 'aggressive']) {
        final strategy = analytics.recommendPlacementStrategy(
          opponentStats,
          stratType,
        );
        strategies.add(strategy);
      }

      setState(() {
        recommendations = strategies;
        if (strategies.isNotEmpty) {
          recommendedStrategyIndex = 0;
        }
      });
    } catch (e) {
      print('Erreur chargement recommandations: $e');
    }
  }

  Future<List<GameStatistics>> _loadOpponentStats() async {
    // À implémenter selon la logique de votre app
    return [];
  }

  void _placeShip(Ship ship, int row, int col) {
    try {
      final gameService = GameService();
      final newBoard = gameService.placeShip(
        board,
        row,
        col,
        ship.type,
        isHorizontal,
      );
      setState(() {
        board = newBoard;
        selectedShip = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Placement invalide: ${e.toString()}')),
      );
    }
  }

  void _autoPlace() {
    try {
      final gameService = GameService();
      final shipTypes = [
        ShipType.carrier,
        ShipType.battleship,
        ShipType.cruiser,
        ShipType.submarine,
        ShipType.destroyer,
      ];

      var tempBoard = Board.empty();
      for (final shipType in shipTypes) {
        bool placed = false;
        var attempts = 0;
        while (!placed && attempts < 100) {
          final row = DateTime.now().microsecond % 10;
          final col = DateTime.now().microsecond % 10;
          final isHoriz = DateTime.now().microsecond % 2 == 0;

          try {
            tempBoard = gameService.placeShip(tempBoard, row, col, shipType, isHoriz);
            placed = true;
          } catch (e) {
            // Réessayer
            attempts++;
          }
        }
      }

      setState(() {
        board = tempBoard;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur placement automatique')),
      );
    }
  }

  void _applyRecommendation() {
    if (recommendations == null || recommendations!.isEmpty) return;

    final strategy = recommendations![recommendedStrategyIndex ?? 0];
    // Appliquer les positions recommandées du strategy.recommendedPositions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Stratégie appliquée: ${strategy.name}')),
    );
  }

  void _complete() {
    if (board.ships.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Placez tous les navires avant de continuer')),
      );
      return;
    }

    widget.onPlacementComplete(board);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Disposition des navires'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _complete,
            tooltip: 'Prêt',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBoard(),
                  SizedBox(height: 24),
                  _buildShipsPanel(),
                  SizedBox(height: 24),
                  if (recommendations != null && recommendations!.isNotEmpty)
                    _buildRecommendationsPanel(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre plateau',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
                childAspectRatio: 1,
              ),
              itemCount: 100,
              itemBuilder: (context, index) {
                final row = index ~/ 10;
                final col = index % 10;
                final cell = board.getCell(row, col);

                Color cellColor = Colors.grey.shade300;
                IconData? icon;

                if (cell.state == CellState.ship) {
                  cellColor = Colors.blue.shade200;
                  icon = Icons.directions_boat;
                } else if (cell.state == CellState.sunk) {
                  cellColor = Colors.red;
                  icon = Icons.close;
                }

                return GestureDetector(
                  onTap: () {
                    if (selectedShip != null) {
                      _placeShip(selectedShip!, row, col);
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: cellColor,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: icon != null
                        ? Icon(icon, size: 16, color: Colors.black)
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipsPanel() {
    final unplacedShips = [
      ShipType.carrier,
      ShipType.battleship,
      ShipType.cruiser,
      ShipType.submarine,
      ShipType.destroyer,
    ].where((type) {
      return !board.ships.any((ship) => ship.type == type);
    }).toList();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Navires à placer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: isHorizontal,
                  onChanged: (value) {
                    setState(() {
                      isHorizontal = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              isHorizontal ? 'Mode: Horizontal' : 'Mode: Vertical',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            SizedBox(height: 12),
            if (unplacedShips.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Tous les navires sont placés!'),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: unplacedShips.length,
                itemBuilder: (context, index) {
                  final type = unplacedShips[index];
                  final size = _getShipSize(type);

                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedShip = Ship(type: type);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sélectionné: ${type.name} (${size}). Cliquez sur le plateau pour placer.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedShip?.type == type
                            ? Colors.blue.shade700
                            : Colors.grey.shade300,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            type.name,
                            style: TextStyle(
                              color: selectedShip?.type == type
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$size'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsPanel() {
    final strategy = recommendations![recommendedStrategyIndex ?? 0];

    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '💡 Recommandation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _applyRecommendation,
                  icon: Icon(Icons.auto_awesome),
                  label: Text('Appliquer'),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              strategy.name,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              strategy.description,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  int _getShipSize(ShipType type) {
    return switch (type) {
      ShipType.carrier => 5,
      ShipType.battleship => 4,
      ShipType.cruiser => 3,
      ShipType.submarine => 3,
      ShipType.destroyer => 2,
    };
  }
}
