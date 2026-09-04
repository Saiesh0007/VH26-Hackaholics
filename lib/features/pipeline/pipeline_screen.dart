import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/pipeline_provider.dart';
import '../../widgets/pipeline_particle_view.dart';
import '../../core/theme/app_colors.dart';
import '../../models/event.dart';

class PipelineScreen extends ConsumerStatefulWidget {
  const PipelineScreen({super.key});

  @override
  ConsumerState<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends ConsumerState<PipelineScreen> {
  String _selectedStage = 'ROUTER';

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(metricsStreamProvider);
    final queuesAsync = ref.watch(queuesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PIPELINE TOPOLOGY CANVAS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Interactive Multi-Stage Ingestion & Routing Architecture',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: metricsAsync.when(
        data: (metrics) {
          final isSpike = metrics.eventRatePerMin > 1000;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Status Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppColors.cardRadius,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AGGREGATE CONDUIT VELOCITY',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${metrics.eventRatePerMin} events/min',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (isSpike ? AppColors.primary : AppColors.healthy).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (isSpike ? AppColors.primary : AppColors.healthy).withOpacity(0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isSpike ? AppColors.primary : AppColors.healthy,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isSpike ? 'AUTONOMOUS BACKPRESSURE' : 'STREAMING FLOW OPTIMAL',
                              style: TextStyle(
                                color: isSpike ? AppColors.primary : AppColors.healthy,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Live Particle Flow Canvas Container
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: AppColors.cardRadius,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: ClipRRect(
                    borderRadius: AppColors.cardRadius,
                    child: Stack(
                      children: [
                        PipelineParticleView(
                          trafficRate: metrics.eventRatePerMin,
                          isFlowMindActive: true,
                        ),
                        Positioned(
                          top: 10,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.cardBorder, width: 0.6),
                            ),
                            child: const Text(
                              'REAL-TIME PACKET FLOW',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _LegendDot(label: 'P0 Critical', color: AppColors.p0Critical),
                                _LegendDot(label: 'P1 Inventory', color: AppColors.p1High),
                                _LegendDot(label: 'P2 Activity', color: AppColors.p2Normal),
                                _LegendDot(label: 'P3 Logs', color: AppColors.p3Low),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Pipeline Architecture Stage Stepper
                const Text(
                  'INTERACTIVE STAGE TOPOLOGY',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),

                // Stages Matrix
                _buildStageNode(
                  id: 'INGRESS',
                  title: '1. Ingress Buffer & Gateway',
                  subtitle: '${metrics.eventRatePerMin} e/min arrival rate',
                  icon: Icons.input_rounded,
                  statusText: 'ONLINE',
                  statusColor: AppColors.healthy,
                  details: 'High-throughput ingress buffer receiving incoming raw payloads from Kafka / webhooks.',
                ),
                _buildStageConnector(),
                _buildStageNode(
                  id: 'CLASSIFIER',
                  title: '2. Priority Semantic Classifier',
                  subtitle: 'Tagging P0, P1, P2, P3 lanes',
                  icon: Icons.alt_route_rounded,
                  statusText: 'ACTIVE',
                  statusColor: AppColors.info,
                  details: 'Zero-latency inspection classifying transactions into isolated priority lanes to eliminate HOL blocking.',
                ),
                _buildStageConnector(),
                _buildStageNode(
                  id: 'ROUTER',
                  title: '3. Tiered Priority Queue Matrix',
                  subtitle: '4 Dedicated Non-Blocking Lanes',
                  icon: Icons.layers_rounded,
                  statusText: isSpike ? 'SURGE TRIAGE' : '100% STREAMING',
                  statusColor: isSpike ? AppColors.primary : AppColors.healthy,
                  details: 'P0 Payments (Zero Drop, Streaming) | P1 Inventory (Batching) | P2 Clicks (Deferral) | P3 Logs (Shedding).',
                ),
                _buildStageConnector(),
                _buildStageNode(
                  id: 'FLOWMIND',
                  title: '4. FlowMind AI Agent Control Core',
                  subtitle: 'Autonomous Policy Hot-Swap',
                  icon: Icons.psychology_rounded,
                  statusText: 'AUTONOMOUS',
                  statusColor: AppColors.agent,
                  details: 'Continuous observe-analyze-propose loop guarded by 4 deterministic SafetyGuard invariants.',
                ),
                _buildStageConnector(),
                _buildStageNode(
                  id: 'WORKERS',
                  title: '5. Dynamic Worker Pool & Sinks',
                  subtitle: '${metrics.throughputPerSec} e/s sink throughput',
                  icon: Icons.storage_rounded,
                  statusText: '16 WORKERS',
                  statusColor: AppColors.healthy,
                  details: 'Downstream commits to BigQuery OLTP, Spillover Deferral Buffer, and Analytics Lakehouse.',
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, __) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.critical))),
      ),
    );
  }

  Widget _buildStageNode({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required String statusText,
    required Color statusColor,
    required String details,
  }) {
    final isSelected = _selectedStage == id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedStage = id;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.2 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.14),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.4), width: 0.6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 8),
              Text(
                details,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStageConnector() {
    return Center(
      child: Container(
        width: 2,
        height: 16,
        margin: const EdgeInsets.symmetric(vertical: 2),
        color: AppColors.cardBorder,
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
