import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/metrics_provider.dart';
import '../../core/theme/app_colors.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(metricsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TELEMETRY INSIGHTS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
      body: metricsAsync.when(
        data: (metrics) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChartCard(
                  title: 'TRAFFIC RATE OVER TIME (EVENTS/MIN)',
                  currentVal: '${metrics.eventRatePerMin} e/min',
                  color: AppColors.info,
                  spots: const [
                    FlSpot(0, 1000),
                    FlSpot(1, 1050),
                    FlSpot(2, 1020),
                    FlSpot(3, 15000),
                    FlSpot(4, 20000),
                    FlSpot(5, 19800),
                  ],
                ),
                const SizedBox(height: 16),
                _buildChartCard(
                  title: 'P0 PAYMENTS VS P3 LOGS LATENCY (MS)',
                  currentVal: 'P0: ${metrics.p0LatencyMs.toInt()}ms | P3: ${metrics.p3LatencyMs.toInt()}ms',
                  color: AppColors.p0Critical,
                  spots: const [
                    FlSpot(0, 42),
                    FlSpot(1, 45),
                    FlSpot(2, 48),
                    FlSpot(3, 52),
                    FlSpot(4, 49),
                    FlSpot(5, 48),
                  ],
                ),
                const SizedBox(height: 16),
                _buildChartCard(
                  title: 'WORKER POOL UTILIZATION (%)',
                  currentVal: '${metrics.workerUtilization.toInt()}%',
                  color: AppColors.agent,
                  spots: const [
                    FlSpot(0, 35),
                    FlSpot(1, 38),
                    FlSpot(2, 42),
                    FlSpot(3, 91),
                    FlSpot(4, 94),
                    FlSpot(5, 88),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String currentVal,
    required Color color,
    required List<FlSpot> spots,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(currentVal, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
