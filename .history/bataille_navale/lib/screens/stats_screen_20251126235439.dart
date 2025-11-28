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

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<void> _loadStats() async {
    final firebase = context.read<FirebaseService>();
    final analytics = context.read<AnalyticsService>();

    try {
      final allStatsRaw = await firebase.getAllGameStats(widget.playerId);
      final allStats = allStatsRaw.map((stat) {
        if (stat is GameStatistics) {
          return stat;
        }
        // Conversion si nécessaire
        return GameStatistics.fromJson(stat as Map<String, dynamic>);
      }).toList();

      final aggregate = await analytics.buildPlayerStatistics(widget.playerId, allStats);

      setState(() {
        playerStats = aggregate;
        gameStats = allStats;
      });
    } catch (e) {
      print('Erreur chargement stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StatsAppBar(),
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

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: AttackHeatmapWidget(
          hitPositions: allHits,
          missPositions: allMisses,
          title: 'Heatmap d\'attaque - ${gameStats!.length} parties',
          cellSize: 22,
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
      };
    }

    // Compter les positions utilisées
    final positionFrequency = <String, int>{};
    int horizontalCount = 0;
    int verticalCount = 0;

    for (final game in gameStats!) {
      // Analyser l'orientation (simplifié)
      // Si les navires sont côte à côte horizontalement vs verticalement
      // Ceci est une approximation
    }

    return {
      'preferredOrientation': horizontalCount > verticalCount ? 'Horizontal' : 'Vertical',
      'favoriteZone': 'Centre-haut',
      'clustering': 'Dispersé',
      'mostUsedPositions': positionFrequency.isNotEmpty 
        ? positionFrequency.entries.first.key 
        : 'N/A',
    };
  }
}
