import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/metrics_provider.dart';
import '../../widgets/pipeline_particle_view.dart';
import '../../core/theme/app_colors.dart';

class PipelineScreen extends ConsumerWidget {
  const PipelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(metricsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PIPELINE ARCHITECTURE CANVAS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
      body: metricsAsync.when(
        data: (metrics) {
          final isSpike = metrics.eventRatePerMin > 5000;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                color: AppColors.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CONDUIT FLOW RATE', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('${metrics.eventRatePerMin} events/min', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isSpike ? AppColors.warning : AppColors.healthy).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isSpike ? '⚡ HIGH VELOCITY SURGE' : '🟢 STABLE CONDUIT FLOW',
                        style: TextStyle(color: isSpike ? AppColors.warning : AppColors.healthy, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    PipelineParticleView(
                      trafficRate: metrics.eventRatePerMin,
                      isFlowMindActive: true,
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            LegendItem(label: 'P0 Payment/Order', color: AppColors.p0Critical),
                            LegendItem(label: 'P1 Inventory', color: AppColors.p1High),
                            LegendItem(label: 'P2 Activity', color: AppColors.p2Normal),
                            LegendItem(label: 'P3 Logs', color: AppColors.p3Low),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const LegendItem({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
