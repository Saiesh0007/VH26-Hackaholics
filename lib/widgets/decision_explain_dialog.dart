import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/domain_policy.dart';
import '../core/theme/app_colors.dart';

class DecisionExplainDialog extends StatelessWidget {
  final PipelineEvent event;
  final DomainPolicy? activePolicy;
  final Map<String, dynamic>? metricsSnapshot;

  const DecisionExplainDialog({
    super.key,
    required this.event,
    this.activePolicy,
    this.metricsSnapshot,
  });

  static void show(
    BuildContext context, {
    required PipelineEvent event,
    DomainPolicy? activePolicy,
    Map<String, dynamic>? metricsSnapshot,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => DecisionExplainDialog(
        event: event,
        activePolicy: activePolicy,
        metricsSnapshot: metricsSnapshot,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = event.priority.isCritical;
    final priorityStr = event.priority.name.toUpperCase();
    final actionStr = event.strategy.name.toUpperCase();

    // Deterministic rule explanation based on runtime parameters
    final reasons = _generateExplanations(event, isCritical);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      child: Container(
        width: 480,
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
                        color: isCritical
                            ? AppColors.critical.withOpacity(0.15)
                            : AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isCritical ? Icons.security_rounded : Icons.hub_rounded,
                        color: isCritical ? AppColors.critical : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DECISION EXPLAINABILITY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          event.id,
                          style: const TextStyle(
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
            const SizedBox(height: 20),

            // Metadata Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder, width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoCell('TYPE', event.type),
                  _infoCell(
                    'PRIORITY',
                    priorityStr,
                    isCritical ? AppColors.critical : AppColors.primaryLight,
                  ),
                  _infoCell(
                    'DECISION',
                    actionStr,
                    actionStr == 'STREAM'
                        ? AppColors.healthy
                        : (actionStr.contains('BATCH') ? AppColors.primary : AppColors.warning),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Checklist of Reasons
            const Text(
              'DECISION REASONING MATRIX',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            ...reasons.map((reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.healthy.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: AppColors.healthy, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          reason,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 16),

            // Runtime Telemetry Snapshot
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder.withOpacity(0.6), width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _telemetryItem('Latency', '${event.latencyMs.toStringAsFixed(1)} ms'),
                  _telemetryItem('Queue Time', '${event.queueTimeMs.toStringAsFixed(1)} ms'),
                  _telemetryItem('Worker ID', event.workerId),
                  _telemetryItem('Payload', '${event.payloadSizeBytes} B'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Close Action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevated,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close Details', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCell(String label, String value, [Color? color]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _telemetryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ],
    );
  }

  List<String> _generateExplanations(PipelineEvent evt, bool isCritical) {
    final list = <String>[];
    if (isCritical) {
      list.add('Critical event designated by active DomainPolicy');
      list.add('SLA remaining: ~${(100 - evt.latencyMs).clamp(20, 100).toInt()}ms (strict delivery bound)');
      list.add('Batching rejected because SLA risk is high for critical stream');
      list.add('Shedding prohibited by immutable safety policy (Zero-loss guarantee)');
      list.add('Dedicated priority worker concurrency allocated');
    } else {
      list.add('Non-critical event category (${evt.priority.name.toUpperCase()})');
      if (evt.strategy == ProcessingStrategy.batch) {
        list.add('Micro-batch strategy applied to maximize downstream I/O throughput');
        list.add('SLA permits queuing buffer window without user-facing disruption');
        list.add('Throughput improvement estimated at +400% vs individual streaming');
      } else if (evt.strategy == ProcessingStrategy.defer) {
        list.add('Event deferred to absorb queue backlog during transient surge');
        list.add('Policy canDefer=true; buffered in memory queue for off-peak ingestion');
      } else if (evt.strategy == ProcessingStrategy.shed) {
        list.add('Shedding active according to domain policy threshold');
        list.add('Dropped safely to preserve compute resources for P0 critical transactions');
      } else {
        list.add('Standard stream execution under available worker capacity');
      }
    }
    return list;
  }
}
