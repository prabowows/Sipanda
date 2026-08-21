import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sipanda_app/core/theme.dart';

class DynamicWeatherCharts extends StatefulWidget {
  const DynamicWeatherCharts({super.key});

  @override
  State<DynamicWeatherCharts> createState() => _DynamicWeatherChartsState();
}

class _DynamicWeatherChartsState extends State<DynamicWeatherCharts> {
  // Toggle between Rainfall and Flood Probability
  bool isShowingRainfall = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SipandaTheme.surface.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(
          top: BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '6-Hour Predictive Analysis',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  _buildLegend(
                    'Rainfall (mm)',
                    SipandaTheme.primary,
                  ),
                  const SizedBox(width: 16),
                  _buildLegend(
                    'Flood Prob (%)',
                    SipandaTheme.statusSiaga,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: LineChart(
              _buildChartData(),
              duration: const Duration(milliseconds: 250),
            ),
          ),
          const SizedBox(height: 16),
          // Analytics summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Current Rain', '23 mm/h', Icons.water_drop, SipandaTheme.primary),
              _buildStatCard('Peak Risk', '84%', Icons.warning_amber, SipandaTheme.statusSiaga),
              _buildStatCard('Sea Level', '+1.2 m', Icons.waves, SipandaTheme.statusWaspada),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegend(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(title, style: const TextStyle(fontSize: 12, color: SipandaTheme.textSecondary)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SipandaTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 10, color: SipandaTheme.textSecondary)),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    return LineChartData(
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final idx = touchedSpot.x.toInt();
              final isPrediction = idx >= 3;
              final timeLabel = isPrediction ? '+${idx - 2}h (Prediksi ML)' : (idx == 0 ? 'T-2h' : (idx == 1 ? 'T-1h' : 'Saat Ini'));
              return LineTooltipItem(
                '[$timeLabel]\n${touchedSpot.y.toStringAsFixed(1)}',
                TextStyle(
                  color: isPrediction ? Colors.amberAccent : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) {
          return const FlLine(color: Colors.white12, strokeWidth: 1, dashArray: [4, 4]);
        },
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 1,
            getTitlesWidget: (value, meta) {
              const style = TextStyle(color: SipandaTheme.textSecondary, fontSize: 11);
              const predStyle = TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold);
              Widget text;
              switch (value.toInt()) {
                case 0:
                  text = const Text('-2h', style: style);
                  break;
                case 1:
                  text = const Text('-1h', style: style);
                  break;
                case 2:
                  text = const Text('Now', style: style);
                  break;
                case 3:
                  text = const Text('+1h (Pred)', style: predStyle);
                  break;
                case 4:
                  text = const Text('+2h (Pred)', style: predStyle);
                  break;
                case 5:
                  text = const Text('+3h (Pred)', style: predStyle);
                  break;
                default:
                  text = const Text('');
              }
              return SideTitleWidget(axisSide: meta.axisSide, child: text);
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text('${value.toInt()}',
                  style: const TextStyle(color: SipandaTheme.textSecondary, fontSize: 10));
            },
            reservedSize: 28,
            interval: 20,
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(bottom: BorderSide(color: Colors.white24, width: 2)),
      ),
      minX: 0,
      maxX: 5,
      minY: 0,
      maxY: 100,
      lineBarsData: [
        // 1. Curah Hujan Aktual (Solid Blue Line)
        LineChartBarData(
          spots: const [
            FlSpot(0, 15),
            FlSpot(1, 28),
            FlSpot(2, 42),
          ],
          isCurved: true,
          color: SipandaTheme.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: SipandaTheme.primary.withOpacity(0.15),
          ),
        ),
        // 2. Curah Hujan Prediksi 3 Jam (Dashed Line + Glowing Dotted Points)
        LineChartBarData(
          spots: const [
            FlSpot(2, 42), // Titik sambungan dari saat ini
            FlSpot(3, 58), // +1 Jam
            FlSpot(4, 72), // +2 Jam
            FlSpot(5, 35), // +3 Jam
          ],
          isCurved: true,
          dashArray: [6, 6],
          color: Colors.amberAccent,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              if (index == 0) return FlDotCirclePainter(radius: 2, color: SipandaTheme.primary);
              return FlDotCirclePainter(
                radius: 5,
                color: spot.y > 60 ? Colors.redAccent : Colors.amberAccent,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
        ),
        // 3. Probabilitas Banjir Prediksi (Dashed Red Line)
        LineChartBarData(
          spots: const [
            FlSpot(0, 10),
            FlSpot(1, 25),
            FlSpot(2, 45),
            FlSpot(3, 68),
            FlSpot(4, 82),
            FlSpot(5, 40),
          ],
          isCurved: true,
          dashArray: [4, 4],
          color: SipandaTheme.statusSiaga,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, barData) => spot.x >= 2,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: spot.y > 70 ? Colors.redAccent : Colors.orangeAccent,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              );
            },
          ),
        ),
      ],
    );
  }
}
