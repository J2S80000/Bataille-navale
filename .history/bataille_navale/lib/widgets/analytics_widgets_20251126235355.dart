import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Heatmap visuelle des positions d'attaque
class AttackHeatmapWidget extends StatelessWidget {
  final List<(int row, int col)> hitPositions;
  final List<(int row, int col)> missPositions;
  final String title;
  final double cellSize;

  const AttackHeatmapWidget({
    Key? key,
    required this.hitPositions,
    required this.missPositions,
    this.title = 'Heatmap d\'attaque',
    this.cellSize = 25,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Créer une grille 10x10 avec intensités
    final grid = List.generate(10, (_) => List.generate(10, (_) => 0.0));
    
    // Marquer les coups
    for (final pos in hitPositions) {
      final row = pos.$1;
      final col = pos.$2;
      if (row >= 0 && row < 10 && col >= 0 && col < 10) {
        grid[row][col] = 1.0; // Hit = fort
      }
    }
    
    for (final pos in missPositions) {
      final row = pos.$1;
      final col = pos.$2;
      if (row >= 0 && row < 10 && col >= 0 && col < 10) {
        grid[row][col] = 0.3; // Miss = faible
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        // Légende
        Row(
          children: [
            SizedBox(width: 100, child: _buildLegendItem('Touché', Colors.red)),
            SizedBox(width: 100, child: _buildLegendItem('Manqué', Colors.lightBlue)),
            SizedBox(width: 100, child: _buildLegendItem('Non visité', Colors.grey.shade300)),
          ],
        ),
        SizedBox(height: 12),
        // Grille heatmap
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: List.generate(10, (row) {
              return Row(
                children: List.generate(10, (col) {
                  final color = _getHeatmapColor(grid[row][col]);
                  
                  return Container(
                    width: cellSize,
                    height: cellSize,
                    margin: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(color: Colors.grey.shade300, width: 0.5),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
        SizedBox(height: 8),
        // Étiquettes colonnes
        Container(
          padding: EdgeInsets.only(left: 16),
          child: Row(
            children: List.generate(10, (col) {
              return SizedBox(
                width: cellSize,
                child: Center(
                  child: Text(
                    '$col',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, border: Border.all(color: Colors.grey)),
        ),
        SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _getHeatmapColor(double intensity) {
    if (intensity == 1.0) {
      return Colors.red.shade600; // Touché = rouge intense
    } else if (intensity == 0.3) {
      return Colors.blue.shade300; // Manqué = bleu
    } else {
      return Colors.grey.shade200; // Non visité = gris
    }
  }
}

/// Graphique en camembert pour les statistiques
class PieChartWidget extends StatelessWidget {
  final Map<String, int> data;
  final String title;
  final Map<String, Color>? colors;

  const PieChartWidget({
    Key? key,
    required this.data,
    required this.title,
    this.colors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<int>(0, (sum, val) => sum + val);
    if (total == 0) {
      return Center(child: Text('Aucune donnée'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 200,
                child: CustomPaint(
                  painter: PieChartPainter(
                    data: data,
                    colors: colors ?? _getDefaultColors(),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data.entries.map((entry) {
                  final percentage = (entry.value / total * 100).toStringAsFixed(1);
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors?[entry.key] ?? _getDefaultColors()[entry.key] ?? Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('${entry.key}: $percentage%', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Map<String, Color> _getDefaultColors() {
    return {
      'Victoires': Colors.green.shade600,
      'Défaites': Colors.red.shade600,
      'Navires coulés': Colors.blue.shade600,
      'Navires restants': Colors.grey.shade400,
    };
  }
}

class PieChartPainter extends CustomPainter {
  final Map<String, int> data;
  final Map<String, Color> colors;

  PieChartPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    final total = data.values.fold<int>(0, (sum, val) => sum + val);
    if (total == 0) return;

    double startAngle = -math.pi / 2;

    data.forEach((label, value) {
      final sweepAngle = (value / total) * 2 * math.pi;
      final color = colors[label] ?? Colors.grey;

      // Dessiner le segment
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        Paint()..color = color,
      );

      // Dessiner la bordure
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );

      startAngle += sweepAngle;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Graphique en barres pour les taux
class BarChartWidget extends StatelessWidget {
  final Map<String, double> data;
  final String title;
  final String yAxisLabel;

  const BarChartWidget({
    Key? key,
    required this.data,
    required this.title,
    this.yAxisLabel = 'Pourcentage (%)',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxValue = data.values.isEmpty ? 100 : (data.values.reduce((a, b) => a > b ? a : b) * 1.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(yAxisLabel, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
              SizedBox(height: 8),
              ...data.entries.map((entry) {
                final percentage = entry.value;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 24,
                          color: Colors.grey.shade200,
                          child: FractionallySizedBox(
                            widthFactor: percentage / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue.shade400, Colors.blue.shade700],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Statistiques de placement des navires
class ShipPlacementAnalysisWidget extends StatelessWidget {
  final Map<String, dynamic> placementPatterns;
  final String title;

  const ShipPlacementAnalysisWidget({
    Key? key,
    required this.placementPatterns,
    this.title = 'Analyse de placement des navires',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.blue.shade50,
          ),
          child: Column(
            children: [
              _buildAnalysisRow('Orientation préférée', 
                placementPatterns['preferredOrientation'] ?? 'Non défini'),
              _buildAnalysisRow('Zone favori', 
                placementPatterns['favoriteZone'] ?? 'Dispersée'),
              _buildAnalysisRow('Regroupement', 
                placementPatterns['clustering'] ?? 'Moyen'),
              if (placementPatterns['mostUsedPositions'] != null)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Positions les plus utilisées:', 
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          placementPatterns['mostUsedPositions'].toString(),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
