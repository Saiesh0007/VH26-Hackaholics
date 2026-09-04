import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ReplaySpikeDialog extends StatelessWidget {
  const ReplaySpikeDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const ReplaySpikeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      child: Container(
        width: 620,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.history_toggle_off_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TIME-TRAVEL BENCHMARK',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          '20× Traffic Surge Comparison Replay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Workload Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder, width: 0.8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppColors.critical, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Workload Input: 20,000 events/min (20× Surge) | Duration: 5 mins',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Comparison Table
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.2),
                1: FlexColumnWidth(1.6),
                2: FlexColumnWidth(1.6),
              },
              children: [
                // Header Row
                TableRow(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  children: [
                    _cellHeader('METRIC'),
                    _cellHeader('NAIVE (FIFO / STREAM)'),
                    _cellHeader('ADAPTQ ENGINE'),
                  ],
                ),
                _metricRow('P0 Latency (Critical)', '4,850 ms (Breached)', '38.5 ms (Guaranteed)', isBetter: true),
                _metricRow('P1 Latency', '14,200 ms', '58.0 ms', isBetter: true),
                _metricRow('P2 Latency', '38,000 ms', '175.0 ms', isBetter: true),
                _metricRow('P3 Latency', '72,000 ms', '420.0 ms', isBetter: true),
                _metricRow('Critical Events Dropped', '3,680 (18.4%)', '0 DROPPED (0.0%)', isBetter: true, isCriticalMetric: true),
                _metricRow('Deferred Backlog', '0 (Queue Stalled)', '1,850 buffered', isBetter: true),
                _metricRow('Worker Utilization', '100% (Crashing)', '89% (Regulated)', isBetter: true),
                _metricRow('Compute Cost / Hour', '\$128.40', '\$38.20 (-70%)', isBetter: true),
              ],
            ),
            const SizedBox(height: 20),

            // Summary verdict card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.healthy.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.healthy.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_rounded, color: AppColors.healthy, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AdaptQ maintains 100% critical data safety and sub-50ms P0 SLA by dynamically converting P2 to micro-batches and selectively shedding P3 telemetry.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.healthy,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close Replay Benchmark', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cellHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  TableRow _metricRow(
    String label,
    String naive,
    String adaptq, {
    bool isBetter = false,
    bool isCriticalMetric = false,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCriticalMetric ? FontWeight.w700 : FontWeight.w500,
              color: isCriticalMetric ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Text(
            naive,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.critical,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Text(
            adaptq,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isBetter ? AppColors.healthy : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
