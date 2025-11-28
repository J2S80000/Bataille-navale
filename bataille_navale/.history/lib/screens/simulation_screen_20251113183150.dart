import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/index.dart';

class SimulationScreen extends StatefulWidget {
  final String playerId;

  const SimulationScreen({
    super.key,
    required this.playerId,
  });

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  int _gameCount = 10;
  bool _isSimulating = false;
  int _simulatedGames = 0;
  List<GameStatistics> _results = [];
  PlayerStatisticsAggregate? _aggregateStats;
  final TextEditingController _countController = TextEditingController(text: '10');

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  Future<void> _startSimulation() async {
    if (_gameCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le nombre de parties doit être > 0')),
      );
      return;
    }

    setState(() {
      _isSimulating = true;
      _simulatedGames = 0;
      _results = [];
      _aggregateStats = null;
    });

    try {
      final firebase = context.read<FirebaseService>();
      
      final games = await SimulationService.simulateGames(
        count: _gameCount,
        playerId: widget.playerId,
        opponentId: 'ai_simulator',
        onProgress: (current, total) {
          setState(() {
            _simulatedGames = current;
          });
        },
      );

      setState(() {
        _results = games;
        _aggregateStats = SimulationService.calculateAggregateStats(
          widget.playerId,
          games,
        );
        _isSimulating = false;
      });

      // Sauvegarder dans MongoDB/Firebase
      for (final game in games) {
        await firebase.saveGameStatistics(game);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Simulation terminée! $_gameCount parties sauvegardées'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSimulating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.play_circle, size: 24, color: Colors.white),
            SizedBox(width: 8),
            Text('Simulateur de parties'),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section paramètres
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Paramètres de simulation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _countController,
                      decoration: InputDecoration(
                        labelText: 'Nombre de parties',
                        hintText: '10',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.gamepad),
                        suffixText: 'parties',
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !_isSimulating,
                      onChanged: (value) {
                        setState(() {
                          _gameCount = int.tryParse(value) ?? 10;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Chaque partie sera simulée complètement et les statistiques sauvegardées.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Bouton de simulation
            if (!_isSimulating)
              ElevatedButton.icon(
                onPressed: _startSimulation,
                icon: Icon(Icons.play_arrow),
                label: Text('Lancer la simulation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 16),
                ),
              )
            else
              SizedBox(
                height: 180,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Simulation en cours...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '$_simulatedGames / $_gameCount parties',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _gameCount > 0 ? _simulatedGames / _gameCount : 0,
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            SizedBox(height: 24),

            // Résultats
            if (_aggregateStats != null) ...[
              Row(
                children: [
                  Icon(Icons.bar_chart, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Résultats agrégés',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildStatsCard(
                title: 'Parties jouées',
                value: _aggregateStats!.totalGames.toString(),
                icon: Icons.gamepad,
                color: Colors.blue,
              ),
              SizedBox(height: 8),
              _buildStatsCard(
                title: 'Victoires',
                value: '${_aggregateStats!.totalWins} (${_aggregateStats!.winRate.toStringAsFixed(1)}%)',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              SizedBox(height: 8),
              _buildStatsCard(
                title: 'Défaites',
                value: _aggregateStats!.totalLosses.toString(),
                icon: Icons.cancel,
                color: Colors.red,
              ),
              SizedBox(height: 8),
              _buildStatsCard(
                title: 'Précision moyenne',
                value: '${_aggregateStats!.averageAccuracy.toStringAsFixed(1)}%',
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
              SizedBox(height: 8),
              _buildStatsCard(
                title: 'Total de coups touchés',
                value: _aggregateStats!.totalHits.toString(),
                icon: Icons.check,
                color: Colors.purple,
              ),
              SizedBox(height: 8),
              _buildStatsCard(
                title: 'Total de coups manqués',
                value: _aggregateStats!.totalMisses.toString(),
                icon: Icons.close,
                color: Colors.grey,
              ),
              SizedBox(height: 24),

              // Détails des parties
              Text(
                '🎯 Détail des parties',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final game = _results[index];
                  return _buildGameResultCard(game, index + 1);
                },
              ),
            ] else if (!_isSimulating && _simulatedGames > 0)
              Center(
                child: Column(
                  children: [
                    SizedBox(height: 32),
                    Icon(Icons.check_circle, size: 48, color: Colors.green),
                    SizedBox(height: 16),
                    Text('Simulation terminée!'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameResultCard(GameStatistics game, int gameNumber) {
    final resultColor = game.won ? Colors.green : Colors.red;
    final resultText = game.won ? '✓ Victoire' : '✗ Défaite';

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$gameNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: resultColor,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resultText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: resultColor,
                    ),
                  ),
                  Text(
                    '${game.hits} hits / ${game.totalMoves} shots (${game.accuracy.toStringAsFixed(1)}%)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${game.gameDuration.inSeconds}s',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${game.recordedAt.hour}:${game.recordedAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
