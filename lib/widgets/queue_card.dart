import 'package:flutter/material.dart';
import '../models/queue_metrics.dart';
import '../models/event.dart';
import '../core/theme/app_colors.dart';
import 'priority_badge.dart';
import 'animated_counter.dart';

class PriorityQueueCard extends StatelessWidget {
  final PriorityQueueMetrics queueMetrics;

  const PriorityQueueCard({
    super.key,
    required this.queueMetrics,
  });

  @override
  Widget build(BuildContext context) {
    final isP0 = queueMetrics.priority.isCritical;

    Color priorityColor;
    switch (queueMetrics.priority) {
      case WorkloadPriority.p0Payment:
      case WorkloadPriority.p0Order:
        priorityColor = AppColors.p0Critical;
        break;
      case WorkloadPriority.p1Inventory:
        priorityColor = AppColors.p1High;
        break;
      case WorkloadPriority.p2Activity:
        priorityColor = AppColors.p2Normal;
        break;
      case WorkloadPriority.p3Log:
        priorityColor = AppColors.p3Low;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isP0 ? priorityColor.withOpacity(0.6) : AppColors.cardBorder,
          width: isP0 ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 6,
            children: [
              PriorityBadge(priority: queueMetrics.priority),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  queueMetrics.activeStrategy.name.toUpperCase(),
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QUEUE DEPTH',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedCounter(
                      value: queueMetrics.queueDepth,
                      suffix: ' events',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${queueMetrics.latencyMs.toInt()} ms',
                style: TextStyle(
                  color: queueMetrics.latencyMs > 200
                      ? AppColors.warning
                      : AppColors.healthy,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress Capacity Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (queueMetrics.capacityPercentage / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(
                queueMetrics.capacityPercentage > 75
                    ? AppColors.critical
                    : (queueMetrics.capacityPercentage > 40
                        ? AppColors.warning
                        : AppColors.healthy),
              ),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 4,
            children: [
              Text(
                'Capacity: ${queueMetrics.capacityPercentage.toInt()}%',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
              Text(
                'Throughput: ${queueMetrics.throughputPerSec} e/s',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
