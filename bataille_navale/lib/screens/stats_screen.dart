import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../widgets/app_bars.dart';
import '../widgets/analytics_widgets.dart';
import '../ai/genetic_algorithm.dart';
import '../ai/neural_network.dart';

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
  bool isLoading = false;
  int totalLoadedGames = 0; // Suivi du nombre de jeux chargés
  bool isLoadingMore = false; // Suivi du chargement supplémentaire

  @override
  void initState() {
    super.initState();
    print('[STATS] Init avec playerId: ${widget.playerId}');
    _statsFuture = _loadStats();
  }

  Future<void> _loadStats() async {
    if (isLoading) return;
    
    setState(() => isLoading = true);
    final mongoService = MongoDBService();
    final analytics = context.read<AnalyticsService>();

    try {
      print('[STATS] Chargement des stats pour ${widget.playerId}...');
      
      // Charger les 1000 premières parties depuis MongoDB
      await mongoService.initialize();
      final first1000 = await mongoService.getPlayerStatistics(widget.playerId, maxRecords: 1000);
      
      print('[STATS] ${first1000.length} parties chargées (max 1000)');

      if (first1000.isEmpty) {
        print('[STATS] ⚠️ Aucune partie trouvée pour $widget.playerId');
        setState(() {
          playerStats = null;
          gameStats = [];
          isLoading = false;
          totalLoadedGames = 0;
        });
        return;
      }

      // Charger les stats agrégées avec les 1000 premières
      print('[STATS] Traitement des ${first1000.length} premières statistiques...');
      final aggregate = await analytics.buildPlayerStatistics(widget.playerId, first1000);

      print('[STATS] ✅ Stats agrégées: ${aggregate.totalGames} parties');
      
      setState(() {
        playerStats = aggregate;
        gameStats = first1000;
        isLoading = false;
        totalLoadedGames = first1000.length;
      });
      
    } catch (e) {
      print('❌ Erreur chargement stats: $e');
      setState(() {
        playerStats = null;
        gameStats = [];
        isLoading = false;
      });
    }
  }

  /// Charge les parties supplémentaires en arrière-plan par batches de 1000
  Future<void> _loadMoreGamesInBackground(
    MongoDBService mongoService,
    AnalyticsService analytics,
    List<GameStatistics> initialStats,
  ) async {
    try {
      print('[STATS] Chargement des parties supplémentaires par batches de 1000...');
      
      int currentLimit = 2000; // Commencer à 2000 pour avoir le prochain batch
      int previousCount = initialStats.length;
      int maxAttempts = 50; // Limiter à 50 batches (50 000 parties max)
      int attempts = 0;
      
      // Charger progressivement par batches de 1000
      while (attempts < maxAttempts) {
        attempts++;
        print('[STATS] Batch $attempts: Chargement jusquà $currentLimit parties...');
        
        // Libérer le thread principal AVANT de faire l'appel réseau
        await Future.delayed(Duration(milliseconds: 100));
        
        final moreStats = await mongoService.getPlayerStatistics(widget.playerId, maxRecords: currentLimit);
        
        if (moreStats.length <= previousCount) {
          // Pas de nouvelles données
          print('[STATS] ✅ Toutes les données chargées: ${previousCount} parties au total');
          break;
        }
        
        final newCount = moreStats.length - previousCount;
        print('[STATS] 📊 +$newCount parties chargées (total: ${moreStats.length})');
        
        // Mettre à jour l'UI avec mise à jour granulaire
        if (mounted) {
          try {
            // Traiter les nouvelles données hors du thread principal
            final updatedAggregate = await analytics.buildPlayerStatistics(widget.playerId, moreStats);
            
            // Libérer le thread AVANT setState
            await Future.microtask(() {});
            
            if (mounted) {
              setState(() {
                gameStats = moreStats;
                playerStats = updatedAggregate;
                totalLoadedGames = moreStats.length;
              });
              
              // Notifier l'utilisateur du progrès (sans bloquer)
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📊 Batch $attempts: ${moreStats.length} parties (+$newCount)'),
                  duration: Duration(milliseconds: 500),
                ),
              );
            }
          } catch (e) {
            print('[STATS] ⚠️ Erreur lors du traitement du batch $attempts: $e');
          }
        }
        
        previousCount = moreStats.length;
        currentLimit += 1000; // Charger les 1000 suivantes
        
        // Délai plus court mais avec libération du thread
        await Future.delayed(Duration(milliseconds: 200));
        await Future.microtask(() {}); // Forcer le rendu
      }
      
      if (attempts >= maxAttempts) {
        print('[STATS] ⚠️ Limite de batches atteinte (${attempts * 1000} parties max)');
      }
    } catch (e) {
      print('[STATS] ❌ Erreur lors du chargement des parties supplémentaires: $e');
    }
  }

  /// Charge uniquement les nouvelles données depuis la dernière mise à jour
  Future<void> _loadNewGamesOnly() async {
    if (isLoadingMore || gameStats == null) return;
    
    setState(() => isLoadingMore = true);
    final mongoService = MongoDBService();
    final analytics = context.read<AnalyticsService>();
    
    try {
      final currentCount = gameStats!.length;
      print('[STATS] Recherche de nouvelles données depuis $currentCount parties...');
      
      // Charger toutes les données
      await mongoService.initialize();
      final allStats = await mongoService.getPlayerStatistics(widget.playerId, maxRecords: currentCount + 1000);
      
      final newCount = allStats.length - currentCount;
      
      if (newCount > 0) {
        print('[STATS] ✨ ${newCount} nouvelles parties trouvées!');
        
        // Recalculer les stats agrégées
        final updatedAggregate = await analytics.buildPlayerStatistics(widget.playerId, allStats);
        
        setState(() {
          gameStats = allStats;
          playerStats = updatedAggregate;
          totalLoadedGames = allStats.length;
          isLoadingMore = false;
        });
        
        // Afficher notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ ${newCount} nouvelle${newCount > 1 ? 's' : ''} partie${newCount > 1 ? 's' : ''} ajoutée${newCount > 1 ? 's' : ''}!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => isLoadingMore = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Aucune nouvelle donnée'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      setState(() => isLoadingMore = false);
      print('[STATS] ❌ Erreur lors du chargement des nouvelles données: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Erreur lors de la récupération des données'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Charge les 1000 prochaines parties
  Future<void> _loadNext1000() async {
    if (isLoadingMore || gameStats == null) return;
    
    setState(() => isLoadingMore = true);
    final mongoService = MongoDBService();
    final analytics = context.read<AnalyticsService>();
    
    try {
      final currentCount = gameStats!.length;
      final nextLimit = currentCount + 1000;
      print('[STATS] Chargement des parties $currentCount à $nextLimit...');
      
      await mongoService.initialize();
      final allStats = await mongoService.getPlayerStatistics(widget.playerId, maxRecords: nextLimit);
      
      final newCount = allStats.length - currentCount;
      
      if (newCount > 0) {
        print('[STATS] ✨ ${newCount} parties chargées!');
        
        final updatedAggregate = await analytics.buildPlayerStatistics(widget.playerId, allStats);
        
        setState(() {
          gameStats = allStats;
          playerStats = updatedAggregate;
          totalLoadedGames = allStats.length;
          isLoadingMore = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('➕ ${newCount} parties chargées! (Total: ${allStats.length})'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        setState(() => isLoadingMore = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Fin des données'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      setState(() => isLoadingMore = false);
      print('[STATS] ❌ Erreur: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Erreur lors du chargement'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Charge TOUTES les parties
  Future<void> _loadAll() async {
    if (isLoadingMore || gameStats == null) return;
    
    setState(() => isLoadingMore = true);
    final mongoService = MongoDBService();
    final analytics = context.read<AnalyticsService>();
    
    try {
      print('[STATS] Chargement de TOUTES les parties...');
      
      await mongoService.initialize();
      final allStats = await mongoService.getPlayerStatistics(widget.playerId, maxRecords: 999999);
      
      final newCount = allStats.length - gameStats!.length;
      
      if (newCount >= 0) {
        print('[STATS] 📊 ${allStats.length} parties chargées au total!');
        
        final updatedAggregate = await analytics.buildPlayerStatistics(widget.playerId, allStats);
        
        setState(() {
          gameStats = allStats;
          playerStats = updatedAggregate;
          totalLoadedGames = allStats.length;
          isLoadingMore = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎯 Toutes les ${allStats.length} parties chargées!'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => isLoadingMore = false);
      }
    } catch (e) {
      setState(() => isLoadingMore = false);
      print('[STATS] ❌ Erreur: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Erreur lors du chargement'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StatsAppBar(),
      body: FutureBuilder(
        future: _statsFuture,
        builder: (context, snapshot) {
          // Afficher le loader pendant le chargement initial
          if (snapshot.connectionState == ConnectionState.waiting && playerStats == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des statistiques...'),
                  SizedBox(height: 8),
                  Text(
                    '(Cette opération peut prendre quelques secondes)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Afficher message si aucune donnée
          if (playerStats == null || gameStats == null || gameStats!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.data_usage, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune statistique disponible'),
                  SizedBox(height: 8),
                  Text(
                    'PlayerId: ${widget.playerId}',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      print('[STATS] Rafraîchissement manuel depuis écran vide...');
                      setState(() {
                        _statsFuture = _loadStats();
                      });
                    },
                    icon: Icon(Icons.refresh),
                    label: Text('Rafraîchir'),
                  ),
                ],
              ),
            );
          }

          // Afficher les statistiques
          return RefreshIndicator(
            onRefresh: () async {
              print('[STATS] Rafraîchissement via pull-down...');
              await _loadStats();
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statistiques',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${gameStats!.length} parties',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      // Bouton: Charger 1000 prochaines
                      Tooltip(
                        message: 'Charger 1000 prochaines parties',
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            backgroundColor: Colors.blue.shade600,
                          ),
                          onPressed: isLoadingMore ? null : _loadNext1000,
                          icon: isLoadingMore 
                            ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                            : Icon(Icons.add, size: 18),
                          label: Text(
                            isLoadingMore ? '...' : '+1K',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      // Bouton: Charger tout
                      Tooltip(
                        message: 'Charger toutes les parties',
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            backgroundColor: Colors.green.shade600,
                          ),
                          onPressed: isLoadingMore ? null : _loadAll,
                          icon: isLoadingMore 
                            ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                            : Icon(Icons.cloud_download, size: 18),
                          label: Text(
                            isLoadingMore ? '...' : 'Tout',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      // Bouton de rafraîchissement
                      IconButton(
                        icon: Icon(Icons.refresh),
                        tooltip: 'Rafraîchir toutes les données',
                        onPressed: () {
                          print('[STATS] Rafraîchissement manuel (bouton)...');
                          setState(() {
                            _statsFuture = _loadStats();
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildOverviewCard(),
                  SizedBox(height: 24),
                  _buildAccuracyCard(),
                  SizedBox(height: 24),
                  _buildWinRateCard(),
                  SizedBox(height: 24),
                  _buildDuelMetricsCard(),
                  SizedBox(height: 24),
                  _buildHotspotCard(),
                  SizedBox(height: 24),
                  // Nouvelles sections analytiques
                  _buildAttackHeatmapSection(),
                  SizedBox(height: 24),
                  _buildWinRateChartSection(),
                  SizedBox(height: 24),
                  _buildShipAnalysisSection(),
                  SizedBox(height: 24),
                  _buildAITrainingCard(),
                ],
              ),
            ),
          );
        }
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

  /// Métriques détaillées des duels
  Widget _buildDuelMetricsCard() {
    if (gameStats == null || gameStats!.isEmpty) {
      return SizedBox.shrink();
    }

    final metrics = _calculateDuelMetrics();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚔️ Analyse des duels',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            // Durée moyenne
            _buildMetricRow('⏱️ Durée moyenne', metrics['averageDuration']),
            _buildMetricRow('📊 Durée min/max', metrics['durationRange']),
            _buildMetricRow('🎯 Coups par minute', metrics['movesPerMinute']),
            _buildMetricRow('💢 Coups moyens/partie', metrics['averageMoves']),
            _buildMetricRow('🎪 Taux de précision moyen', metrics['averageAccuracy']),
            _buildMetricRow('⚡ Navires coulés/victoire', metrics['shipsPerWin']),
            SizedBox(height: 12),
            Divider(color: Colors.grey.shade300),
            SizedBox(height: 12),
            Text(
              'Statistiques de performance',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
            ),
            SizedBox(height: 8),
            _buildMetricRow('🏆 Victoires rapides', metrics['quickWins']),
            _buildMetricRow('🐢 Victoires longues', metrics['longWins']),
            _buildMetricRow('⚠️ Défaites rapides', metrics['quickLosses']),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text(
            value ?? '-',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// Calcule les métriques de duel
  Map<String, String> _calculateDuelMetrics() {
    if (gameStats == null || gameStats!.isEmpty) {
      return {};
    }

    final games = gameStats!;
    final totalDuration = games.fold<Duration>(
      Duration.zero,
      (sum, game) => sum + game.gameDuration,
    );
    final averageDuration = totalDuration.inSeconds ~/ games.length;
    
    // Durée min/max
    final durations = games.map((g) => g.gameDuration.inSeconds).toList();
    durations.sort();
    final minDuration = durations.first;
    final maxDuration = durations.last;
    
    // Coups par minute
    final totalMoves = games.fold<int>(0, (sum, g) => sum + g.totalMoves);
    final totalMinutes = totalDuration.inSeconds / 60;
    final movesPerMinute = (totalMoves / (totalMinutes > 0 ? totalMinutes : 1)).toStringAsFixed(1);
    
    // Coups moyens
    final averageMoves = (totalMoves / games.length).toStringAsFixed(1);
    
    // Précision moyenne
    final averageAccuracy = (games.fold<double>(0, (sum, g) => sum + g.accuracy) / games.length).toStringAsFixed(1);
    
    // Navires coulés par victoire
    final winGames = games.where((g) => g.won).toList();
    final totalShipsDestroyed = winGames.fold<int>(0, (sum, g) => sum + g.shipsDestroyed);
    final shipsPerWin = winGames.isNotEmpty 
        ? (totalShipsDestroyed / winGames.length).toStringAsFixed(1)
        : '0';
    
    // Victoires rapides (moins de 2 minutes)
    final quickWins = games.where((g) => g.won && g.gameDuration.inSeconds < 120).length;
    
    // Victoires longues (plus de 5 minutes)
    final longWins = games.where((g) => g.won && g.gameDuration.inSeconds > 300).length;
    
    // Défaites rapides
    final quickLosses = games.where((g) => !g.won && g.gameDuration.inSeconds < 120).length;

    return {
      'averageDuration': '${(averageDuration ~/ 60)}m ${averageDuration % 60}s',
      'durationRange': '${minDuration ~/ 60}m - ${maxDuration ~/ 60}m',
      'movesPerMinute': '$movesPerMinute coups/min',
      'averageMoves': '$averageMoves coups',
      'averageAccuracy': '$averageAccuracy%',
      'shipsPerWin': '$shipsPerWin navires',
      'quickWins': '$quickWins parties < 2min',
      'longWins': '$longWins parties > 5min',
      'quickLosses': '$quickLosses défaites < 2min',
    };
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

  Widget _buildAITrainingCard() {
    final hasGames = gameStats != null && gameStats!.isNotEmpty;

    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: Colors.amber.shade700, size: 24),
                SizedBox(width: 12),
                Text(
                  'Entraîner l\'IA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Analysez vos patterns de jeu pour adapter l\'IA à votre stratégie.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasGames
                    ? () => _trainAI()
                    : null,
                icon: Icon(Icons.psychology),
                label: Text('Analyser et adapter l\'IA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (!hasGames) ...[
              SizedBox(height: 12),
              Text(
                '⚠️ Vous avez besoin d\'au moins une partie pour entraîner l\'IA',
                style: TextStyle(fontSize: 11, color: Colors.red, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _trainAI() async {
    if (gameStats == null || gameStats!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aucune partie disponible pour l\'entraînement')),
      );
      return;
    }

    // Afficher un dialog de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Analyse en cours...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyse de vos patterns de jeu...'),
          ],
        ),
      ),
    );

    try {
      // Analyser le comportement du joueur
      final placementPatterns = PlayerBehaviorService.analyzeShipPlacementPatterns(gameStats!);
      final attackPatterns = PlayerBehaviorService.analyzeAttackPatterns(gameStats!);

      // Générer une stratégie adaptée
      final adaptiveStrategy = PlayerBehaviorService.generateAdaptiveStrategy(
        placementPatterns: placementPatterns,
        attackPatterns: attackPatterns,
        strategyId: 'adaptive_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Identifier les zones à cibler
      final highRiskZones = PlayerBehaviorService.identifyHighRiskZones(placementPatterns);

      // Fermer le dialog
      Navigator.of(context).pop();

      // Afficher les résultats avec les données pour l'entraînement
      _showAITrainingResults(
        placementPatterns: placementPatterns,
        attackPatterns: attackPatterns,
        adaptiveStrategy: adaptiveStrategy,
        highRiskZones: highRiskZones,
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'analyse: $e')),
      );
    }
  }

  void _showAITrainingResults({
    required Map<String, dynamic> placementPatterns,
    required Map<String, dynamic> attackPatterns,
    required AIStrategy adaptiveStrategy,
    required List<(int, int)> highRiskZones,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📊 Analyse de l\'IA complétée'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profil du joueur
              Text(
                'Votre profil:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 8),
              _buildProfileInfo('Stratégie détectée', attackPatterns['strategy'] as String),
              _buildProfileInfo(
                'Préférence placement',
                '${((placementPatterns['centerPreference'] as num) * 100).toStringAsFixed(0)}% centre',
              ),
              _buildProfileInfo(
                'Prédictabilité',
                '${(attackPatterns['predictability'] as num).toStringAsFixed(1)}%',
              ),
              SizedBox(height: 16),

              // Stratégie de l'IA
              Text(
                'Stratégie IA générée:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 8),
              _buildWeightInfo('Proximité', adaptiveStrategy.weights[0]),
              _buildWeightInfo('Densité', adaptiveStrategy.weights[1]),
              _buildWeightInfo('Espacement', adaptiveStrategy.weights[2]),
              _buildWeightInfo('Hotspots', adaptiveStrategy.weights[3]),
              _buildWeightInfo('Exploration', adaptiveStrategy.weights[4]),
              SizedBox(height: 16),

              // Zones à cibler
              if (highRiskZones.isNotEmpty) ...[
                Text(
                  'Zones à cibler:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),
                ...highRiskZones.asMap().entries.map((e) {
                  final index = e.key;
                  final (row, col) = e.value;
                  final position = '${String.fromCharCode(65 + col)}${row + 1}';
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('  ${index + 1}. Zone $position'),
                  );
                }),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Afficher un dialog de progression
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: Text('Entraînement en cours...'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Les IA s\'entraînent sur vos patterns...'),
                      SizedBox(height: 8),
                      Text(
                        'Cela peut prendre quelques secondes',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
              
              // Entraîner tous les modèles IA en arrière-plan
              _trainAllAIModelsInBackground(
                placementPatterns: placementPatterns,
                attackPatterns: attackPatterns,
              );
            },
            child: Text('Entraîner les IA'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _trainAllAIModelsInBackground({
    required Map<String, dynamic> placementPatterns,
    required Map<String, dynamic> attackPatterns,
  }) {
    // Lancer l'entraînement après un délai pour laisser le dialog s'afficher
    Future.delayed(Duration(milliseconds: 500), () async {
      try {
        final mongoService = MongoDBService();
        
        // Charger les modèles existants
        final models = await AIModelManager.loadUserModels(widget.playerId, mongoService);

        // Utiliser PLUS de données pour un meilleur entraînement
        // Augmenté de 10 à 50 parties (ou tout l'historique si moins disponible)
        final recentGamesLimited = (gameStats ?? []).length > 50
            ? (gameStats ?? []).sublist((gameStats?.length ?? 0) - 50)
            : gameStats ?? [];

        print('[TRAIN] Entraînement avec ${recentGamesLimited.length} parties (max 50)');

        // Entraîner tous les modèles EN PARALLÈLE
        final trainingFutures = <Future<void>>[];
        
        for (final difficulty in ['easy', 'medium', 'hard', 'expert']) {
          if (models.containsKey(difficulty)) {
            trainingFutures.add(_trainSingleModel(
              model: models[difficulty]!,
              difficulty: difficulty,
              recentGames: recentGamesLimited,
              placementPatterns: placementPatterns,
              attackPatterns: attackPatterns,
              mongoService: mongoService,
            ));
          }
        }

        // Attendre que tous les entraînements soient terminés
        await Future.wait(trainingFutures);

        print('[TRAIN] Tous les modèles ont été entraînés');

        // Fermer le dialog de progression et afficher le succès
        if (mounted) {
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Les 4 IA ont été entraînées avec votre profil!'),
              duration: Duration(seconds: 4),
              backgroundColor: Colors.green,
            ),
          );
          
          // Rafraîchir les statistiques
          setState(() {
            _statsFuture = _loadStats();
          });
        }
      } catch (e) {
        print('[ERREUR TRAIN] Erreur lors de l\'entraînement: $e');
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur lors de l\'entraînement: $e'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    });
  }

  Future<void> _trainSingleModel({
    required NeuralNetworkAI model,
    required String difficulty,
    required List<GameStatistics> recentGames,
    required Map<String, dynamic> placementPatterns,
    required Map<String, dynamic> attackPatterns,
    required MongoDBService mongoService,
  }) async {
    try {
      print('[TRAIN] Démarrage entraînement $difficulty...');
      
      // Adapter les données d'entraînement selon la difficulté
      List<GameStatistics> trainingGames = recentGames;
      
      switch (difficulty) {
        case 'easy':
          // Easy: utilise que les 5 dernières parties (apprentissage limité mais basé sur comportement récent)
          trainingGames = recentGames.length > 5
              ? recentGames.sublist(recentGames.length - 5)
              : recentGames;
          break;
        case 'medium':
          // Medium: utilise les 10 dernières parties
          trainingGames = recentGames.length > 10
              ? recentGames.sublist(recentGames.length - 10)
              : recentGames;
          break;
        case 'hard':
          // Hard: utilise les 20 dernières parties
          trainingGames = recentGames.length > 20
              ? recentGames.sublist(recentGames.length - 20)
              : recentGames;
          break;
        case 'expert':
          // Expert: utilise TOUTES les parties (apprentissage complet)
          trainingGames = recentGames;
          break;
      }
      
      print('[TRAIN] $difficulty: utilise ${trainingGames.length} parties pour l\'entraînement');
      
      // Entraîner le modèle avec les données spécifiques à sa difficulté
      final trainedModel = await AIModelManager.trainModelWithDifficulty(
        model: model,
        recentGames: trainingGames,
        playerBehavior: {
          'placementPatterns': placementPatterns,
          'attackPatterns': attackPatterns,
        },
        difficulty: difficulty,
      );

      // Sauvegarder le modèle entraîné
      await AIModelManager.saveModel(
        trainedModel,
        widget.playerId,
        mongoService,
      );

      print('[TRAIN] ✓ Modèle $difficulty entraîné (${trainedModel.trainingIterations} entraînements accumulés)');
    } catch (e) {
      print('[ERREUR TRAIN] Erreur modèle $difficulty: $e');
    }
  }

  Widget _buildWeightInfo(String label, double weight) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontSize: 11)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: weight,
                minHeight: 6,
              ),
            ),
          ),
          SizedBox(width: 8),
          Text(
            '${(weight * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Heatmap des attaques du joueur
  Widget _buildAttackHeatmapSection() {
    if (gameStats == null || gameStats!.isEmpty) {
      return SizedBox.shrink();
    }

    // Agréger les positions de tous les jeux
    final allHits = <(int, int)>[];
    final allMisses = <(int, int)>[];

    for (final game in gameStats!) {
      allHits.addAll(game.hitPositions);
      allMisses.addAll(game.missPositions);
    }

    print('[HEATMAP] Parties: ${gameStats!.length}');
    print('[HEATMAP] Total hits: ${allHits.length}');
    print('[HEATMAP] Total misses: ${allMisses.length}');
    
    if (gameStats!.isNotEmpty) {
      print('[HEATMAP] Premier jeu - hits: ${gameStats!.first.hitPositions.length}, misses: ${gameStats!.first.missPositions.length}');
      print('[HEATMAP] Premier jeu - hitPositions: ${gameStats!.first.hitPositions.take(5)}');
      print('[HEATMAP] Premier jeu - missPositions: ${gameStats!.first.missPositions.take(5)}');
    }

    // Créer une heatmap 10x10 simple si le widget ne marche pas
    if (allHits.isEmpty && allMisses.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Heatmap d\'attaque - ${gameStats!.length} parties',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Aucune donnée de coups',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Heatmap d\'attaque - ${gameStats!.length} parties',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '${allHits.length} touchers, ${allMisses.length} manqués',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 16),
            // Grille simple 10x10
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
              itemCount: 100,
              itemBuilder: (context, index) {
                final row = index ~/ 10;
                final col = index % 10;
                
                // Compter les hits et misses à cette position
                final hitCount = allHits.where((p) => p.$1 == row && p.$2 == col).length;
                final missCount = allMisses.where((p) => p.$1 == row && p.$2 == col).length;
                
                Color cellColor;
                if (hitCount > 0) {
                  // Dégradé du jaune au rouge selon l'intensité
                  final intensity = (hitCount*6 / (hitCount + missCount)).clamp(0, 1) as double;
                  cellColor = Color.lerp(Colors.yellow, Colors.red, intensity)!;
                } else if (missCount > 0) {
                  cellColor = Colors.blue.shade200;
                } else {
                  cellColor = Colors.grey.shade300;
                }
                
                return Container(
                  margin: EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: cellColor,
                    border: Border.all(color: Colors.grey.shade400, width: 0.5),
                  ),
                  child: Center(
                    child: hitCount > 0 
                      ? Text(
                          hitCount.toString(),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                        )
                      : SizedBox.shrink(),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            // Légende
            Row(
              children: [
                Container(width: 20, height: 20, color: Colors.yellow, margin: EdgeInsets.only(right: 8)),
                Text('Coups', style: TextStyle(fontSize: 11)),
                SizedBox(width: 16),
                Container(width: 20, height: 20, color: Colors.red, margin: EdgeInsets.only(right: 8)),
                Text('Nombreux coups', style: TextStyle(fontSize: 11)),
                SizedBox(width: 16),
                Container(width: 20, height: 20, color: Colors.blue, margin: EdgeInsets.only(right: 8)),
                Text('Manqués', style: TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Graphique du taux de victoire
  Widget _buildWinRateChartSection() {
    final stats = playerStats!;
    final totalGames = stats.totalGames;
    
    if (totalGames == 0) return SizedBox.shrink();

    final winRate = ((stats.totalWins / totalGames) * 100);
    final lossRate = ((stats.totalLosses / totalGames) * 100);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: BarChartWidget(
          data: {
            'Victoires': winRate,
            'Défaites': lossRate,
          },
          title: 'Taux de victoire',
          yAxisLabel: 'Pourcentage (%)',
        ),
      ),
    );
  }

  /// Analyse du placement des navires
  Widget _buildShipAnalysisSection() {
    if (gameStats == null || gameStats!.isEmpty) {
      return SizedBox.shrink();
    }

    // Analyser les patterns de placement
    final placementPatterns = _analyzeShipPlacement();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: ShipPlacementAnalysisWidget(
          placementPatterns: placementPatterns,
          title: 'Analyse du placement des navires',
        ),
      ),
    );
  }

  /// Analyse les patterns de placement des navires
  Map<String, dynamic> _analyzeShipPlacement() {
    if (gameStats == null || gameStats!.isEmpty) {
      return {
        'preferredOrientation': 'N/A',
        'favoriteZone': 'N/A',
        'clustering': 'N/A',
        'mostUsedPositions': 'Aucune donnée',
      };
    }

    // Compter les positions touchées (indique où les navires sont usuellement placés)
    final positionHitCount = <String, int>{};
    int horizontalPatterns = 0;
    int verticalPatterns = 0;
    final topPositions = <String, int>{};
    final bottomPositions = <String, int>{};
    final leftPositions = <String, int>{};
    final rightPositions = <String, int>{};
    final centerPositions = <String, int>{};

    for (final game in gameStats!) {
      // Analyser les positions touchées
      for (final (row, col) in game.hitPositions) {
        final posKey = '($row,$col)';
        positionHitCount[posKey] = (positionHitCount[posKey] ?? 0) + 1;

        // Classifier par zone
        if (row < 3) {
          topPositions[posKey] = (topPositions[posKey] ?? 0) + 1;
        } else if (row > 6) {
          bottomPositions[posKey] = (bottomPositions[posKey] ?? 0) + 1;
        }

        if (col < 3) {
          leftPositions[posKey] = (leftPositions[posKey] ?? 0) + 1;
        } else if (col > 6) {
          rightPositions[posKey] = (rightPositions[posKey] ?? 0) + 1;
        } else if (row >= 3 && row <= 6 && col >= 3 && col <= 6) {
          centerPositions[posKey] = (centerPositions[posKey] ?? 0) + 1;
        }

        // Déterminer orientation (simplifié)
        if (col > row) {
          horizontalPatterns++;
        } else {
          verticalPatterns++;
        }
      }
    }

    // Trouver les positions les plus utilisées
    final topPositionsList = positionHitCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final mostUsedPositions = topPositionsList
        .take(3)
        .map((e) => '${e.key}: ${e.value}x')
        .join(', ');

    // Déterminer la zone favorite
    String favoriteZone = 'Dispersée';
    int maxZone = 0;
    
    if (topPositions.values.fold(0, (a, b) => a + b) > maxZone) {
      maxZone = topPositions.values.fold(0, (a, b) => a + b);
      favoriteZone = 'Haut';
    }
    if (bottomPositions.values.fold(0, (a, b) => a + b) > maxZone) {
      maxZone = bottomPositions.values.fold(0, (a, b) => a + b);
      favoriteZone = 'Bas';
    }
    if (leftPositions.values.fold(0, (a, b) => a + b) > maxZone) {
      maxZone = leftPositions.values.fold(0, (a, b) => a + b);
      favoriteZone = 'Gauche';
    }
    if (rightPositions.values.fold(0, (a, b) => a + b) > maxZone) {
      favoriteZone = 'Droite';
    }
    if (centerPositions.values.fold(0, (a, b) => a + b) > maxZone) {
      favoriteZone = 'Centre';
    }

    // Clustering - densité des coups
    final uniquePositions = positionHitCount.length;
    final totalHits = gameStats!.fold<int>(0, (sum, g) => sum + g.hitPositions.length);
    final clustering = uniquePositions > 0 
        ? (totalHits / uniquePositions).toStringAsFixed(1)
        : '0';

    return {
      'preferredOrientation': horizontalPatterns > verticalPatterns ? 'Horizontal' : 'Vertical',
      'favoriteZone': favoriteZone,
      'clustering': 'Densité: $clustering coups/position',
      'mostUsedPositions': mostUsedPositions.isNotEmpty ? mostUsedPositions : 'Variées',
      'totalPositionsAttempted': uniquePositions,
      'totalHits': totalHits,
    };
  }
}
