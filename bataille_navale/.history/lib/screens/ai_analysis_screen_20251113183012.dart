import 'package:flutter/material.dart';
import '../ai/index.dart';
import '../models/index.dart';

class AIAnalysisScreen extends StatefulWidget {
  final List<GameStatistics> playerHistory;
  final String playerId;

  const AIAnalysisScreen({
    super.key,
    required this.playerHistory,
    required this.playerId,
  });

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen> {
  late NeuralNetworkBattleshipAI aiAnalyzer;
  bool _isTraining = false;

  @override
  void initState() {
    super.initState();
    aiAnalyzer = NeuralNetworkBattleshipAI(playerHistory: widget.playerHistory);
  }

  void _trainNetwork() {
    setState(() {
      _isTraining = true;
    });

    // Entraîner en arrière-plan
    Future.delayed(Duration(milliseconds: 500), () {
      aiAnalyzer.trainNetwork();
      setState(() {
        _isTraining = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Réseau de neurones entraîné!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final strategy = aiAnalyzer.generateAdaptiveStrategy();
    final skillRating = aiAnalyzer.getOpponentSkillRating();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, size: 24, color: Colors.white),
            SizedBox(width: 8),
            Text('Analyse IA'),
          ],
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bouton d'entraînement
            if (!_isTraining)
              ElevatedButton.icon(
                onPressed: _trainNetwork,
                icon: Icon(Icons.school),
                label: Text('Entraîner le NN'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              )
            else
              Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Entraînement en cours...'),
                  ],
                ),
              ),
            SizedBox(height: 24),

            // Profil du joueur
            Text(
              '👤 Profil du joueur',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildProfileCard(strategy, skillRating),
            SizedBox(height: 24),

            // Style de jeu
            Text(
              '🎮 Style de jeu détecté',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildStyleCard(strategy['style']),
            SizedBox(height: 24),

            // Heatmap des coups
            Text(
              '🔥 Heatmap des zones ciblées',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildHeatmap(),
            SizedBox(height: 24),

            // Prédictions
            Text(
              '🎯 Prédictions de placement des navires',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildShipPredictionHeatmap(),
            SizedBox(height: 24),

            // Recommandations
            Text(
              '💡 Recommandations stratégiques',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ...(strategy['recommendations'] as List<String>)
                .map((rec) => _buildRecommendationCard(rec))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> strategy, double skillRating) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileRow('Parties analysées', '${widget.playerHistory.length}'),
            SizedBox(height: 8),
            _buildProfileRow(
              'Compétence',
              '${(skillRating * 100).toStringAsFixed(1)}%',
            ),
            SizedBox(height: 8),
            _buildProfileRow(
              'Style dominant',
              strategy['style'].toString().toUpperCase(),
            ),
            SizedBox(height: 8),
            _buildProfileRow(
              'Progression',
              strategy['progression']['trend'].toString().replaceAll('_', ' '),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStyleCard(String style) {
    final colors = {
      'aggressive': Colors.red,
      'defensive': Colors.blue,
      'random': Colors.orange,
      'balanced': Colors.green,
    };

    final descriptions = {
      'aggressive':
          'Attaques rapides et concentrées dans certaines zones',
      'defensive': 'Approche prudente avec coups espacés',
      'random': 'Patterns imprévisibles et variés',
      'balanced': 'Mélange équilibré de tactiques',
    };

    return Card(
      color: colors[style]?.withValues(alpha: 0.1),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              style.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors[style],
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              descriptions[style] ?? '',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
        ),
        itemCount: 100,
        itemBuilder: (context, index) {
          final row = index ~/ 10;
          final col = index % 10;
          final intensity = aiAnalyzer.heatmap[row][col];

          return Container(
            decoration: BoxDecoration(
              color: _getHeatmapColor(intensity),
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
            child: Center(
              child: Text(
                (intensity * 100).toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 8,
                  color: intensity > 0.5 ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShipPredictionHeatmap() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
        ),
        itemCount: 100,
        itemBuilder: (context, index) {
          final row = index ~/ 10;
          final col = index % 10;
          final probability = aiAnalyzer.shipPredictions[row][col];

          return Container(
            decoration: BoxDecoration(
              color: _getShipPredictionColor(probability),
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
            child: Center(
              child: Text(
                (probability * 100).toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 8,
                  color: probability > 0.5 ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationCard(String recommendation) {
    final isWarning = recommendation.startsWith('⚠️');
    final isPositive = recommendation.startsWith('✓');

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: isWarning
          ? Colors.red.withValues(alpha: 0.1)
          : isPositive
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.blue.withValues(alpha: 0.1),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          recommendation,
          style: TextStyle(
            color: isWarning
                ? Colors.red
                : isPositive
                    ? Colors.green
                    : Colors.blue,
          ),
        ),
      ),
    );
  }

  Color _getHeatmapColor(double intensity) {
    // Dégradé rouge
    if (intensity < 0.25) return Colors.blue;
    if (intensity < 0.5) return Colors.cyan;
    if (intensity < 0.75) return Colors.yellow;
    return Colors.red;
  }

  Color _getShipPredictionColor(double probability) {
    // Dégradé violet
    if (probability < 0.25) return Colors.grey.shade200;
    if (probability < 0.5) return Colors.purple.shade200;
    if (probability < 0.75) return Colors.purple.shade400;
    return Colors.purple.shade700;
  }
}
