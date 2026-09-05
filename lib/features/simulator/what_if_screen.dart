import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/domain_provider.dart';
import '../../providers/metrics_provider.dart';

class WhatIfScreen extends ConsumerStatefulWidget {
  const WhatIfScreen({super.key});

  @override
  ConsumerState<WhatIfScreen> createState() => _WhatIfScreenState();
}

class _WhatIfScreenState extends ConsumerState<WhatIfScreen> {
  double _trafficRate = 20000;
  int _workers = 8;
  int _batchSize = 100;

  Map<String, dynamic>? _simulationResult;

  @override
  void initState() {
    super.initState();
    _runSimulation();
  }

  Future<void> _runSimulation() async {
    final domainState = ref.read(domainProvider);
    final aiService = ref.read(aiDomainServiceProvider);

    final res = await aiService.simulateWhatIf(
      policy: domainState.activePolicy,
      trafficRate: _trafficRate,
      workers: _workers,
      batchSize: _batchSize,
    );

    if (mounted) {
      setState(() {
        _simulationResult = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final domainState = ref.watch(domainProvider);
    final metricsAsync = ref.watch(metricsStreamProvider);
    final currentMetrics = metricsAsync.value;

    final predicted = _simulationResult?['predicted'] as Map<String, dynamic>?;
    final explanation = _simulationResult?['explanation']?.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'WHAT-IF PREDICTIVE SIMULATOR',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Controls Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SIMULATION INPUT PARAMETERS',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMuted,
                            letterSpacing: 0.8),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Domain: ${domainState.activePolicy.domainName}',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryLight),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Traffic Rate Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Projected Traffic Rate',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text('${_trafficRate.toInt()} events/min',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryLight)),
                    ],
                  ),
                  Slider(
                    value: _trafficRate,
                    min: 1000,
                    max: 100000,
                    divisions: 99,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceElevated,
                    onChanged: (val) {
                      setState(() => _trafficRate = val);
                      _runSimulation();
                    },
                  ),

                  // Worker Count Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Worker Nodes',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text('$_workers workers',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryLight)),
                    ],
                  ),
                  Slider(
                    value: _workers.toDouble(),
                    min: 1,
                    max: 32,
                    divisions: 31,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceElevated,
                    onChanged: (val) {
                      setState(() => _workers = val.toInt());
                      _runSimulation();
                    },
                  ),

                  // Batch Size Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Batch Size Threshold',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text('$_batchSize items',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryLight)),
                    ],
                  ),
                  Slider(
                    value: _batchSize.toDouble(),
                    min: 10,
                    max: 500,
                    divisions: 49,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceElevated,
                    onChanged: (val) {
                      setState(() => _batchSize = val.toInt());
                      _runSimulation();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Comparison: CURRENT vs PREDICTED
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CURRENT RUNTIME vs PREDICTED IMPACT',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 560,
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2.0),
                          1: FlexColumnWidth(1.5),
                          2: FlexColumnWidth(1.5),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            children: [
                              _cellHeader('METRIC'),
                              _cellHeader('CURRENT'),
                              _cellHeader('PREDICTED'),
                            ],
                          ),
                          _comparisonRow(
                            'P0 Latency (Critical)',
                            '${currentMetrics?.p0LatencyMs.toStringAsFixed(1) ?? "38.5"} ms',
                            '${predicted?['p0_latency_ms'] ?? "--"} ms',
                            highlight: true,
                          ),
                          _comparisonRow(
                            'P1 Latency',
                            '${currentMetrics?.p1LatencyMs.toStringAsFixed(1) ?? "54.0"} ms',
                            '${predicted?['p1_latency_ms'] ?? "--"} ms',
                          ),
                          _comparisonRow(
                            'P2 Latency',
                            '${currentMetrics?.p2LatencyMs.toStringAsFixed(1) ?? "120.0"} ms',
                            '${predicted?['p2_latency_ms'] ?? "--"} ms',
                          ),
                          _comparisonRow(
                            'P3 Latency',
                            '${currentMetrics?.p3LatencyMs.toStringAsFixed(1) ?? "350.0"} ms',
                            '${predicted?['p3_latency_ms'] ?? "--"} ms',
                          ),
                          _comparisonRow(
                            'Critical Events Lost',
                            '${currentMetrics?.criticalEventsLost ?? 0}',
                            '${predicted?['critical_dropped'] ?? 0} (0-Loss Guarantee)',
                            highlight: true,
                            isHealthy: true,
                          ),
                          _comparisonRow(
                            'Deferred Rate',
                            '${currentMetrics?.totalDeferredCount ?? 0}',
                            '${predicted?['deferred_percent'] ?? "0.0"}%',
                          ),
                          _comparisonRow(
                            'Shedding Rate',
                            '${currentMetrics?.totalShedCount ?? 0}',
                            '${predicted?['shed_percent'] ?? "0.0"}%',
                          ),
                          _comparisonRow(
                            'Est. Cost / Hour',
                            '\$3.60',
                            '\$${predicted?['estimated_cost_per_hour'] ?? "0.00"}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            if (explanation != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology_rounded,
                        color: AppColors.primaryLight, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        explanation,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cellHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted),
      ),
    );
  }

  TableRow _comparisonRow(String label, String current, String predicted,
      {bool highlight = false, bool isHealthy = false}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color:
                  highlight ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Text(
            current,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Text(
            predicted,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isHealthy
                  ? AppColors.healthy
                  : (highlight
                      ? AppColors.primaryLight
                      : AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
