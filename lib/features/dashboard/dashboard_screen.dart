import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/flowmind_provider.dart';
import '../../providers/pipeline_provider.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/queue_card.dart';
import '../../widgets/agent_status_indicator.dart';
import '../../widgets/pressure_gauge.dart';
import '../../widgets/animated_counter.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/domain_provider.dart';
import '../domain/create_pipeline_screen.dart';
import '../simulator/what_if_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  double? _draggedSliderValue;

  static const List<int> _snapPoints = [
    1000,
    20000,
    40000,
    60000,
    80000,
    100000
  ];

  int _snapToNearest(double raw) {
    int best = _snapPoints[0];
    double minDiff = (raw - best).abs();
    for (final pt in _snapPoints) {
      final diff = (raw - pt).abs();
      if (diff < minDiff) {
        minDiff = diff;
        best = pt;
      }
    }
    return best;
  }

  String _getMultiplierLabel(int rate) {
    if (rate <= 1000) return '1× Baseline';
    final mult = (rate / 1000).round();
    if (rate >= 100000) return '${mult}× Extreme Stress';
    if (rate >= 60000) return '${mult}× Black Friday';
    return '${mult}× Surge';
  }

  Color _getSurgeColor(int rate) {
    if (rate <= 1000) return AppColors.healthy;
    if (rate <= 20000) return AppColors.primary;
    if (rate <= 60000) return AppColors.primaryLight;
    return AppColors.critical;
  }

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(metricsStreamProvider);
    final queuesAsync = ref.watch(queuesStreamProvider);
    final agentStateAsync = ref.watch(agentStateStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: AppColors.surface,
                border: Border.all(color: AppColors.cardBorder, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3060A5FA),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AdaptQ',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Autonomous Pipeline Intelligence',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 21),
            tooltip: 'What-If Predictive Simulator',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WhatIfScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: metricsAsync.when(
        data: (metrics) {
          final isSpike = metrics.eventRatePerMin > 1000;
          final currentTraffic =
              _draggedSliderValue?.round() ?? metrics.eventRatePerMin;
          final activeColor = _getSurgeColor(currentTraffic);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Agent Status Chip
                agentStateAsync.when(
                  data: (agentState) =>
                      AgentStatusIndicator(state: agentState.state),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),

                // Active Pipeline Domain Selector
                _buildDomainSelector(context, ref),
                const SizedBox(height: 14),

                // Hero Ingestion & Multi-Tier Traffic Surge Controller
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppColors.cardRadiusLarge,
                    border: Border.all(
                      color: isSpike
                          ? activeColor.withOpacity(0.8)
                          : AppColors.cardBorder,
                      width: isSpike ? 1.4 : 0.8,
                    ),
                    boxShadow: isSpike
                        ? [
                            BoxShadow(
                              color: activeColor.withOpacity(0.18),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ]
                        : AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSpike
                                  ? activeColor.withOpacity(0.16)
                                  : AppColors.surfaceElevated,
                              borderRadius: AppColors.pillRadius,
                              border: Border.all(
                                color: isSpike
                                    ? activeColor.withOpacity(0.4)
                                    : AppColors.cardBorder,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSpike
                                      ? Icons.bolt_rounded
                                      : Icons.sync_rounded,
                                  size: 13,
                                  color: isSpike
                                      ? activeColor
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isSpike
                                      ? 'SURGE LOAD INGESTION'
                                      : 'REAL-TIME INGRESS CONDUIT',
                                  style: TextStyle(
                                    color: isSpike
                                        ? activeColor
                                        : AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSpike
                                  ? activeColor.withOpacity(0.15)
                                  : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getMultiplierLabel(currentTraffic),
                              style: TextStyle(
                                color:
                                    isSpike ? activeColor : AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AnimatedCounter(
                        value: currentTraffic,
                        suffix: ' e/min',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSpike
                            ? 'Dynamic FlowMind backpressure & prioritization active.'
                            : 'Pipeline healthy. All workloads streaming within target SLAs.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Multi-Tier Traffic Slider (1k to 100k)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TRAFFIC VELOCITY LEVER',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '$currentTraffic e/min',
                            style: TextStyle(
                              color: activeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: activeColor,
                          inactiveTrackColor: AppColors.surfaceElevated,
                          thumbColor: Colors.white,
                          overlayColor: activeColor.withOpacity(0.2),
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 9),
                          trackHeight: 6,
                        ),
                        child: Slider(
                          value:
                              currentTraffic.toDouble().clamp(1000.0, 100000.0),
                          min: 1000,
                          max: 100000,
                          divisions: 5,
                          onChanged: (val) {
                            setState(() {
                              _draggedSliderValue =
                                  _snapToNearest(val).toDouble();
                            });
                          },
                          onChangeEnd: (val) {
                            final targetRate = _snapToNearest(val);
                            setState(() {
                              _draggedSliderValue = null;
                            });
                            ref
                                .read(pipelineRepositoryProvider)
                                .setTrafficRate(targetRate);
                          },
                        ),
                      ),

                      // Discrete Snap Chips (1k, 20k, 40k, 60k, 80k, 100k)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _snapPoints.map((pt) {
                          final isSelected = currentTraffic == pt;
                          final label =
                              pt >= 1000 ? '${(pt / 1000).toInt()}k' : '$pt';
                          return InkWell(
                            onTap: () {
                              ref
                                  .read(pipelineRepositoryProvider)
                                  .setTrafficRate(pt);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? activeColor.withOpacity(0.2)
                                    : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? activeColor
                                      : AppColors.cardBorder,
                                  width: isSelected ? 1.2 : 0.6,
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    ],
                  ),
                ),
                const SizedBox(height: 14),


                // Section Title - Telemetry
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'REAL-TIME PIPELINE TELEMETRY',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'SLA PROTECTED',
                      style: TextStyle(
                        color: AppColors.healthy,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Telemetry Metrics Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    MetricCard(
                      title: 'System Load',
                      value: metrics.systemLoadPercentage.toInt(),
                      unit: '%',
                      subtitle: 'Worker CPU Pool',
                      valueColor: metrics.systemLoadPercentage > 80
                          ? AppColors.warning
                          : AppColors.healthy,
                      icon: Icons.memory_rounded,
                    ),
                    MetricCard(
                      title: 'Backpressure',
                      value: metrics.queuePressurePercentage.toInt(),
                      unit: '%',
                      subtitle: 'Buffer Resistance',
                      valueColor: metrics.queuePressurePercentage > 50
                          ? AppColors.warning
                          : AppColors.primary,
                      icon: Icons.compress_rounded,
                    ),
                    MetricCard(
                      title: 'Throughput',
                      value: metrics.throughputPerSec,
                      unit: 'e/s',
                      subtitle: 'Processing Speed',
                      valueColor: AppColors.primary,
                      icon: Icons.speed_rounded,
                    ),
                    MetricCard(
                      title: 'P0 Latency',
                      value: metrics.p0LatencyMs.toInt(),
                      unit: 'ms',
                      subtitle: 'Target < 50 ms',
                      valueColor: AppColors.healthy,
                      icon: Icons.timer_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Backpressure Gauge
                BackpressureGauge(
                    queuePressurePercentage: metrics.queuePressurePercentage),
                const SizedBox(height: 20),

                // Priority Queue Workloads Header
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PRIORITY ROUTING MATRIX',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'TIERED HOL PROTECTION',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Priority Queue Cards
                queuesAsync.when(
                  data: (queues) {
                    return Column(
                      children: queues
                          .map((q) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: PriorityQueueCard(queueMetrics: q),
                              ))
                          .toList(),
                    );
                  },
                  loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary)),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, __) => Center(
            child: Text('Error: $err',
                style: const TextStyle(color: AppColors.critical))),
      ),
    );
  }

  Widget _buildDomainSelector(BuildContext context, WidgetRef ref) {
    final domainState = ref.watch(domainProvider);
    final active = domainState.activePolicy;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.hub_rounded, size: 15, color: AppColors.primaryLight),
                  SizedBox(width: 6),
                  Text(
                    'ACTIVE PIPELINE DOMAIN',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreatePipelineScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.primaryLight),
                      SizedBox(width: 4),
                      Text(
                        'AI Architect',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryLight),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...domainState.availablePolicies.map((p) {
                  final isSelected = p.domainName.toLowerCase() == active.domainName.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        p.domainName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceElevated,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      ),
                      onSelected: (_) {
                        ref.read(domainProvider.notifier).switchDomain(p);
                      },
                    ),
                  );
                }),
                ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 14, color: AppColors.primaryLight),
                  label: const Text('+ Create Domain', style: TextStyle(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.w700)),
                  backgroundColor: AppColors.surfaceElevated,
                  side: const BorderSide(color: AppColors.primary, width: 0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreatePipelineScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, size: 14, color: AppColors.healthy),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${active.domainName}: ${active.eventTypes.length} event tiers | 0 critical event loss guarantee active',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
