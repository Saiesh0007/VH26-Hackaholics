import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/pipeline_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/pipeline_metrics.dart';
import '../../widgets/animated_counter.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  int _selectedMetricIndex = 0; // 0: Throughput, 1: P0 Latency, 2: Backpressure, 3: Worker Load
  String _selectedTimeframe = '1m Live';

  static const List<String> _metricsTabs = [
    'Throughput',
    'P0 Latency',
    'Backpressure',
    'Worker Load',
  ];

  static const List<String> _timeframes = ['1m Live', '5m', '15m', '1h'];

  List<FlSpot> _getSpotsForMetric(int metricIdx, PipelineMetrics metrics) {
    final rate = metrics.eventRatePerMin;
    final isSpike = rate > 1000;

    switch (metricIdx) {
      case 0: // Throughput (e/s)
        return isSpike
            ? const [
                FlSpot(0, 320),
                FlSpot(1, 380),
                FlSpot(2, 450),
                FlSpot(3, 1100),
                FlSpot(4, 1450),
                FlSpot(5, 1620),
              ]
            : const [
                FlSpot(0, 280),
                FlSpot(1, 310),
                FlSpot(2, 330),
                FlSpot(3, 315),
                FlSpot(4, 325),
                FlSpot(5, 320),
              ];
      case 1: // P0 Latency (ms)
        return isSpike
            ? const [
                FlSpot(0, 42),
                FlSpot(1, 45),
                FlSpot(2, 48),
                FlSpot(3, 51),
                FlSpot(4, 49),
                FlSpot(5, 48),
              ]
            : const [
                FlSpot(0, 38),
                FlSpot(1, 40),
                FlSpot(2, 39),
                FlSpot(3, 42),
                FlSpot(4, 41),
                FlSpot(5, 40),
              ];
      case 2: // Backpressure (%)
        return isSpike
            ? const [
                FlSpot(0, 12),
                FlSpot(1, 15),
                FlSpot(2, 28),
                FlSpot(3, 72),
                FlSpot(4, 88),
                FlSpot(5, 78),
              ]
            : const [
                FlSpot(0, 10),
                FlSpot(1, 12),
                FlSpot(2, 11),
                FlSpot(3, 14),
                FlSpot(4, 12),
                FlSpot(5, 12),
              ];
      case 3: // Worker Load (%)
      default:
        return isSpike
            ? const [
                FlSpot(0, 35),
                FlSpot(1, 40),
                FlSpot(2, 55),
                FlSpot(3, 89),
                FlSpot(4, 94),
                FlSpot(5, 86),
              ]
            : const [
                FlSpot(0, 32),
                FlSpot(1, 35),
                FlSpot(2, 38),
                FlSpot(3, 34),
                FlSpot(4, 36),
                FlSpot(5, 35),
              ];
    }
  }

  String _getMetricUnit(int idx) {
    switch (idx) {
      case 0:
        return 'e/s';
      case 1:
        return 'ms';
      case 2:
      case 3:
      default:
        return '%';
    }
  }

  String _getCurrentValueString(int idx, PipelineMetrics m) {
    switch (idx) {
      case 0:
        return '${m.throughputPerSec} e/s';
      case 1:
        return '${m.p0LatencyMs.toInt()} ms';
      case 2:
        return '${m.queuePressurePercentage.toInt()}%';
      case 3:
      default:
        return '${m.systemLoadPercentage.toInt()}%';
    }
  }

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
              'TELEMETRY & ANALYTICS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Real-Time Observability & Per-Tier SLA Diagnostics',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: metricsAsync.when(
        data: (metrics) {
          final spots = _getSpotsForMetric(_selectedMetricIndex, metrics);
          final currentValStr = _getCurrentValueString(_selectedMetricIndex, metrics);
          final isSpike = metrics.eventRatePerMin > 1000;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top KPI Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppColors.cardRadius,
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'FLOW METRIC',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _metricsTabs[_selectedMetricIndex].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.healthy.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.healthy.withOpacity(0.4), width: 0.8),
                            ),
                            child: const Text(
                              '100% P0 SLA MET',
                              style: TextStyle(
                                color: AppColors.healthy,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentValStr,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSpike
                            ? 'Surge telemetry actively sampled and prioritized by FlowMind AI.'
                            : 'Normal operating baseline. All metrics within standard bounds.',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 16),

                      // Metric Selector Tabs
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_metricsTabs.length, (idx) {
                            final isSelected = _selectedMetricIndex == idx;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedMetricIndex = idx;
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    _metricsTabs[idx],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                      fontSize: 10.5,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Timeframe Filter Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TIMEFRAME',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: _timeframes.map((tf) {
                              final isSelected = _selectedTimeframe == tf;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedTimeframe = tf;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primaryLight : Colors.transparent,
                                      width: 0.6,
                                    ),
                                  ),
                                  child: Text(
                                    tf,
                                    style: TextStyle(
                                      color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Curved LineChart with Glowing Area
                      SizedBox(
                        height: 160,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 25,
                              getDrawingHorizontalLine: (val) => const FlLine(
                                color: AppColors.divider,
                                strokeWidth: 0.8,
                              ),
                            ),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                curveSmoothness: 0.35,
                                color: AppColors.primary,
                                barWidth: 3.5,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                    radius: index == spots.length - 1 ? 5 : 0,
                                    color: Colors.white,
                                    strokeWidth: 2,
                                    strokeColor: AppColors.primary,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.primary.withOpacity(0.35),
                                      AppColors.primary.withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Per-Tier Latency Benchmark Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppColors.cardRadius,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PER-TIER LATENCY BREAKDOWN',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'SLA AUDIT',
                            style: TextStyle(color: AppColors.info, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Aggregate latency hides the story. AdaptQ ensures critical transactions maintain sub-50ms processing while non-critical logs absorb queue latency.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                      ),
                      const SizedBox(height: 16),

                      // 4 Tiers Latency Bars
                      _buildTierLatencyRow('P0 Payments & Orders', metrics.p0LatencyMs.toInt(), 50, AppColors.healthy, 'STREAM (100% Target Met)'),
                      const SizedBox(height: 12),
                      _buildTierLatencyRow('P1 Inventory Reservation', metrics.p1LatencyMs.toInt(), 200, AppColors.primary, 'BATCH (Dynamic 500)'),
                      const SizedBox(height: 12),
                      _buildTierLatencyRow('P2 Telemetry & Clicks', metrics.p2LatencyMs.toInt(), 500, AppColors.warning, 'DEFER (30s Spillover Buffer)'),
                      const SizedBox(height: 12),
                      _buildTierLatencyRow('P3 System Logs', metrics.p3LatencyMs.toInt(), 1000, AppColors.critical, 'SHED (75% Controlled Drop)'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Workload Distribution Breakdown Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppColors.cardRadius,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INGRESS WORKLOAD COMPOSITION',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildCompositionRow('P0 Payments & Checkout', '20%', AppColors.p0Critical, 'Revenue Protected'),
                      const SizedBox(height: 8),
                      _buildCompositionRow('P1 Inventory Operations', '25%', AppColors.p1High, 'Adaptive Batching'),
                      const SizedBox(height: 8),
                      _buildCompositionRow('P2 User Behavioral Telemetry', '35%', AppColors.p2Normal, 'Deferred Buffer'),
                      const SizedBox(height: 8),
                      _buildCompositionRow('P3 Debug Logs & Traces', '20%', AppColors.p3Low, 'Selectively Sampled'),
                    ],
                  ),
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

  Widget _buildTierLatencyRow(String tier, int latencyMs, int targetSla, Color color, String modeTag) {
    final ratio = (latencyMs / (targetSla * 1.5)).clamp(0.05, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(tier, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
            Row(
              children: [
                Text(
                  '$latencyMs ms',
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Text(
                  '(SLA < $targetSla ms)',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.surfaceElevated,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 4),
        Text(modeTag, style: TextStyle(color: color.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCompositionRow(String name, String percentage, Color dotColor, String strategy) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11)),
        ),
        Text(strategy, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        const SizedBox(width: 10),
        Text(percentage, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
