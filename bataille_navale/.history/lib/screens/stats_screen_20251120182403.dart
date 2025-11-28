import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/index.dart';
import '../services/index.dart';
import 'index.dart';

class StatsScreen extends StatefulWidget {
  final String playerId;

  const StatsScreen({
    Key? key,
    required this.playerId,
  }) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<void> _statsFuture;

  PlayerStatisticsAggregate? playerStats;
  List<GameStatistics>? gameStats;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<void> _loadStats() async {
    final firebase = context.read<FirebaseService>();
    final analytics = context.read<AnalyticsService>();

    try {
      final allStats = await firebase.getAllGameStats(widget.playerId);
      final aggregate = await analytics.buildPlayerStatistics(widget.playerId, allStats.cast<GameStatistics>());

      setState(() {
        playerStats = aggregate;
        gameStats = allStats.cast<GameStatistics>();
      });
    } catch (e) {
      print('Erreur chargement stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistiques'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: FutureBuilder(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (playerStats == null) {
            return Center(child: Text('Aucune statistique disponible'));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCard(),
                SizedBox(height: 24),
                _buildAccuracyCard(),
                SizedBox(height: 24),
                _buildWinRateCard(),
                SizedBox(height: 24),
                _buildHeatmapCard(),
                SizedBox(height: 24),
                _buildAccuracyChartCard(),
                SizedBox(height: 24),
                _buildGameHistoryChartCard(),
                SizedBox(height: 24),
                _buildHotspotCard(),
                SizedBox(height: 24),
                if (gameStats != null && gameStats!.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AIAnalysisScreen(
                            playerHistory: gameStats!,
                            playerId: widget.playerId,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.smart_toy),
                    label: Text('Analyser avec l\'IA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard() {
    final stats = playerStats!;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vue d\'ensemble',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Parties', stats.totalGames.toString()),
                _buildStatColumn('Victoires', stats.totalWins.toString()),
                _buildStatColumn('Défaites', stats.totalLosses.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildAccuracyCard() {
    final stats = playerStats!;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Précision',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAccuracyIndicator(
                  'Coups totaux',
                  (stats.totalHits + stats.totalMisses).toString(),
                ),
                _buildAccuracyIndicator(
                  'Touchers',
                  stats.totalHits.toString(),
                ),
                _buildAccuracyIndicator(
                  'Manqués',
                  stats.totalMisses.toString(),
                ),
                _buildAccuracyIndicator(
                  'Taux',
                  '${stats.averageAccuracy.toStringAsFixed(1)}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyIndicator(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildWinRateCard() {
    final stats = playerStats!;
    final percentage = (stats.winRate * 100).toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Taux de victoire',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: stats.winRate,
                minHeight: 30,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            SizedBox(height: 12),
            Center(
              child: Text(
                '$percentage%',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotspotCard() {
    final stats = playerStats!;
    final analytics = context.read<AnalyticsService>();
    final hotspots = analytics.getHotspots(stats.heatmap, top: 5);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zones privilégiées (Top 5)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: hotspots.length,
              itemBuilder: (context, index) {
                final (row, col, count) = hotspots[index];
                final position = '${String.fromCharCode(65 + col)}${row + 1}';

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(position),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count fois',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
