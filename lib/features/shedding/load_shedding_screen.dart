import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/metrics_provider.dart';
import '../../core/theme/app_colors.dart';

class LoadSheddingScreen extends ConsumerWidget {
  const LoadSheddingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(metricsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CONTROLLED LOAD SHEDDING', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
      body: metricsAsync.when(
        data: (metrics) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: AppColors.healthy, size: 20),
                          SizedBox(width: 8),
                          Text('PROTECTION STATUS: P0 SAFE', style: TextStyle(color: AppColors.healthy, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Under extreme traffic pressure, FlowMind safely samples non-critical P3 logs and defers P2 user activity while guaranteeing 100% processing of P0 Payment and Order workloads.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildCounterCard('DEFERRED WORKLOADS', metrics.totalDeferredCount, AppColors.warning),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCounterCard('SAMPLED / SHED LOGS', metrics.totalShedCount, AppColors.critical),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildCounterCard('CRITICAL P0 EVENTS LOST', metrics.criticalEventsLost, AppColors.healthy),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildCounterCard(String title, int count, Color color) {
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
          Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
