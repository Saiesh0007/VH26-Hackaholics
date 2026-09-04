import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/priority_badge.dart';

class EventTraceScreen extends StatelessWidget {
  final PipelineEvent event;

  const EventTraceScreen({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = event.timestamp.toIso8601String().substring(11, 23);

    return Scaffold(
      appBar: AppBar(
        title: Text('TRACE ${event.id}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Summary Card
            Container(
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
                      Text(
                        '${event.type} EVENT TRACE',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      PriorityBadge(priority: event.priority),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Event ID: ${event.id} | Timestamp: $timeStr',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Timeline Steps
            const Text(
              'LIFECYCLE TIMELINE',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),

            _buildTraceStep(
              stepName: 'INGESTED',
              timestamp: timeStr,
              details: 'Received from edge Gateway API',
              color: AppColors.info,
            ),
            _buildTraceStep(
              stepName: 'CLASSIFIED',
              timestamp: timeStr,
              details: 'Classifier assigned priority: ${event.priority.code} ${event.priority.displayName}',
              color: AppColors.agent,
            ),
            _buildTraceStep(
              stepName: 'ROUTED',
              timestamp: timeStr,
              details: 'Priority Router queued to ${event.priority.displayName} buffer',
              color: AppColors.warning,
            ),
            _buildTraceStep(
              stepName: 'WORKER ASSIGNED',
              timestamp: timeStr,
              details: 'Allocated to ${event.workerId}',
              color: AppColors.info,
            ),
            _buildTraceStep(
              stepName: event.status.name.toUpperCase(),
              timestamp: timeStr,
              details: 'Processed via ${event.strategy.name.toUpperCase()} strategy',
              color: AppColors.healthy,
              isLast: true,
            ),
            const SizedBox(height: 20),

            // Metrics Breakdown Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LATENCY BREAKDOWN',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem('End-to-End Latency', '${event.latencyMs.toInt()} ms', AppColors.textPrimary),
                      _buildMetricItem('Queue Wait Time', '${event.queueTimeMs.toInt()} ms', AppColors.warning),
                      _buildMetricItem('Worker Processing', '${event.processingTimeMs.toInt()} ms', AppColors.info),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 10),
                  const Text(
                    'DECISION REASON',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${event.decisionReason}"',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraceStep({
    required String stepName,
    required String timestamp,
    required String details,
    required Color color,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stepName,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(timestamp, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 2),
              Text(details, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
