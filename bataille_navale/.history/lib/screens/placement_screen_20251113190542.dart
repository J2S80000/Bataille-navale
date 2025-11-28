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
  ShipType? selectedShip;
  bool isHorizontal = true;
  List<InitialPlacementStrategy>? recommendations;
  int? recommendedStrategyIndex;

  @override
  void initState() {
    super.initState();
    board = Board.empty();
    // Ne pas appeler _loadRecommendations ici car context n'est pas disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendations();
    });
  }

  Future<void> _loadRecommendations() async {
    try {
      final analytics = context.read<AdvancedAnalyticsService>();
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

      if (mounted) {
        setState(() {
          recommendations = strategies;
          if (strategies.isNotEmpty) {
            recommendedStrategyIndex = 0;
          }
        });
      }
    } catch (e) {
      print('⚠ Erreur chargement recommandations: $e');
    }
  }

  Future<List<GameStatistics>> _loadOpponentStats() async {
    // À implémenter selon la logique de votre app
    return [];
  }

  void _placeShip(ShipType shipType, int row, int col) {
    try {
      print('Tentative placement: $shipType à ($row, $col), isHorizontal=$isHorizontal');
      
      final gameService = GameService();
      final newBoard = gameService.placeShip(
        board,
        row,
        col,
        shipType,
        isHorizontal,
      );
      
      print('✓ Placement réussi: $shipType');
      
      setState(() {
        board = newBoard;
        selectedShip = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ ${shipType.displayName} placé!'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Erreur placement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Placement invalide: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyRecommendation() {
    if (recommendations == null || recommendations!.isEmpty) return;

    final strategy = recommendations![recommendedStrategyIndex ?? 0];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Stratégie appliquée: ${strategy.strategyName}')),
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
        title: const Row(
          children: [
            Icon(Icons.grid_3x3, size: 24, color: Colors.white),
            SizedBox(width: 8),
            Text('Disposition des navires'),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
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
            SizedBox(height: 8),
            if (selectedShip != null)
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  '👇 Cliquez sur le plateau pour placer ${selectedShip!.displayName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(height: 4),
            GridView.builder(
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

                Color cellColor = Colors.blue.shade50;
                String? displayText;
                Color? textColor;

                if (cell.state == CellState.ship) {
                  cellColor = Colors.blue.shade300;
                  displayText = '⚓';
                  textColor = Colors.blue.shade900;
                } else if (cell.state == CellState.sunk) {
                  cellColor = Colors.red.shade300;
                  displayText = '✕';
                  textColor = Colors.red.shade900;
                } else if (selectedShip != null) {
                  cellColor = Colors.blue.shade100;
                }

                return GestureDetector(
                  onTap: () {
                    if (selectedShip != null) {
                      _placeShip(selectedShip!, row, col);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: cellColor,
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: displayText != null
                          ? Text(
                              displayText,
                              style: TextStyle(
                                fontSize: 18,
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
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
                  'Navires à placer (${unplacedShips.length})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isHorizontal ? Colors.blue.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isHorizontal = !isHorizontal;
                      });
                    },
                    child: Text(
                      isHorizontal ? '⟷ Horizontal' : '⟨ Vertical',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (unplacedShips.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Tous les navires sont placés!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
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
                  final isSelected = selectedShip == type;

                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Material(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedShip = type;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '✓ ${type.displayName} sélectionné\nCliquez sur le plateau pour placer ($size cellules)',
                              ),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.shade400 : Colors.grey.shade100,
                            border: Border.all(
                              color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type.displayName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    '$size cellules',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected ? Colors.blue.shade100 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.arrow_forward,
                                color: isSelected ? Colors.white : Colors.grey,
                              ),
                            ],
                          ),
                        ),
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
              strategy.strategyName,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Taux de victoire attendu: ${(strategy.expectedWinRate * 100).toStringAsFixed(1)}%',
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
