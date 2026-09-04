import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/flowmind_provider.dart';
import '../../providers/pipeline_provider.dart';
import '../../providers/demo_provider.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/queue_card.dart';
import '../../widgets/critical_shield.dart';
import '../../widgets/agent_status_indicator.dart';
import '../../widgets/pressure_gauge.dart';
import '../../widgets/animated_counter.dart';
import '../../core/theme/app_colors.dart';
import '../voice/voice_assistant_dialog.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(metricsStreamProvider);
    final queuesAsync = ref.watch(queuesStreamProvider);
    final agentStateAsync = ref.watch(agentStateStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PULSEFLOW',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Adaptive AI Data Pipeline Command Center',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic, color: AppColors.agent),
            tooltip: 'Ask FlowMind',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const VoiceAssistantDialog(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_fill, color: AppColors.info),
            tooltip: 'Demo Mode',
            onPressed: () {
              ref.read(demoProvider.notifier).startDemo();
            },
          ),
        ],
      ),
      body: metricsAsync.when(
        data: (metrics) {
          final isSpike = metrics.eventRatePerMin > 5000;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Agent Status Header Banner
                agentStateAsync.when(
                  data: (agentState) => AgentStatusIndicator(state: agentState.state),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 14),

                // Hero Metric Banner (EVENT RATE)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSpike ? AppColors.critical.withOpacity(0.7) : AppColors.cardBorder,
                      width: isSpike ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isSpike ? '🔥 20× SURGE RATE' : 'EVENT INGESTION RATE',
                                style: TextStyle(
                                  color: isSpike ? AppColors.critical : AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          AnimatedCounter(
                            value: metrics.eventRatePerMin,
                            suffix: ' events/min',
                            style: TextStyle(
                              color: isSpike ? AppColors.critical : AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isSpike ? 'Adaptive FlowMind Control Active' : 'Normal Baseline Operations',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      // Spike / Recover CTA Action Buttons
                      Column(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSpike ? AppColors.healthy : AppColors.critical,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onPressed: () {
                              final repo = ref.read(pipelineRepositoryProvider);
                              if (isSpike) {
                                repo.recover();
                              } else {
                                repo.triggerSpike();
                              }
                            },
                            child: Text(
                              isSpike ? '🟢 RECOVER' : '🔥 20× SPIKE',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Predictive Load Warning Banner if pressure building
                if (metrics.queuePressurePercentage > 30) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'FlowMind predicts P3 queue saturation if current traffic rate continues.',
                            style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Critical Event Shield
                CriticalShield(
                  isExtremeSpike: isSpike,
                  criticalLost: metrics.criticalEventsLost,
                ),
                const SizedBox(height: 16),

                // Telemetry Metrics Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.7,
                  children: [
                    MetricCard(
                      title: 'System Load',
                      value: metrics.systemLoadPercentage.toInt(),
                      unit: '%',
                      subtitle: 'Worker Pool CPU Utilization',
                      valueColor: metrics.systemLoadPercentage > 80 ? AppColors.warning : AppColors.healthy,
                      icon: Icons.memory,
                    ),
                    MetricCard(
                      title: 'Queue Pressure',
                      value: metrics.queuePressurePercentage.toInt(),
                      unit: '%',
                      subtitle: 'Backpressure Gauge',
                      valueColor: metrics.queuePressurePercentage > 50 ? AppColors.warning : AppColors.info,
                      icon: Icons.compress,
                    ),
                    MetricCard(
                      title: 'Throughput',
                      value: metrics.throughputPerSec,
                      unit: 'e/s',
                      subtitle: 'Active Processing Speed',
                      valueColor: AppColors.info,
                      icon: Icons.speed,
                    ),
                    MetricCard(
                      title: 'P0 Latency',
                      value: metrics.p0LatencyMs.toInt(),
                      unit: 'ms',
                      subtitle: 'Payment/Order Target < 60ms',
                      valueColor: AppColors.healthy,
                      icon: Icons.timer,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Backpressure Gauge
                BackpressureGauge(queuePressurePercentage: metrics.queuePressurePercentage),
                const SizedBox(height: 16),

                // Priority Queue Cards Header
                const Text(
                  'PRIORITY QUEUE WORKLOADS',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),

                // 4 Priority Queue Cards
                queuesAsync.when(
                  data: (queues) {
                    return Column(
                      children: queues
                          .map((q) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: PriorityQueueCard(queueMetrics: q),
                              ))
                          .toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
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
}
