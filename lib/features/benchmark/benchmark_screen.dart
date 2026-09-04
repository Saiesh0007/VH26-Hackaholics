import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BenchmarkScreen extends StatelessWidget {
  const BenchmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NAIVE VS ADAPTQ BENCHMARK', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SIMULATED BENCHMARK: Performance comparison under 20× traffic surge (20,000 events/min).',
                      style: TextStyle(color: AppColors.info, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Comparison Table Container
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: AppColors.surfaceElevated,
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('METRIC', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('NAIVE PIPELINE', style: TextStyle(color: AppColors.critical, fontSize: 10, fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('ADAPTQ AI', style: TextStyle(color: AppColors.healthy, fontSize: 10, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _buildBenchmarkRow('Critical P0 Events Lost', '4,281 (42% dropped)', '0 (100% Protected)', isWinner: true),
                  _buildBenchmarkRow('P0 Payment Latency', '2,840 ms', '48 ms', isWinner: true),
                  _buildBenchmarkRow('Priority Awareness', 'None (FIFO Queue)', 'P0 → P3 Tiered Router', isWinner: true),
                  _buildBenchmarkRow('Adaptive Batching', 'Disabled (Overhead)', 'Dynamic (250-500)', isWinner: true),
                  _buildBenchmarkRow('Backpressure Management', 'System Crash / Drop', 'Controlled Intake', isWinner: true),
                  _buildBenchmarkRow('Non-Critical Handling', 'Queued until failure', 'Controlled Sampling', isWinner: true),
                  _buildBenchmarkRow('Overall System State', '💥 TOTAL COLLAPSE', '🛡 STABLE ADAPTIVE', isWinner: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenchmarkRow(String metric, String naiveVal, String pulseVal, {required bool isWinner}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(metric, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text(naiveVal, style: const TextStyle(color: AppColors.critical, fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(pulseVal, style: const TextStyle(color: AppColors.healthy, fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
