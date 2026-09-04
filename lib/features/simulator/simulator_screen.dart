import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  double _trafficRate = 20000;
  double _workerCount = 12;
  double _batchSize = 250;
  double _processingCostMs = 25;

  bool _hasSimulated = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WHAT-IF SIMULATOR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Text(
                'Simulate hypothetical pipeline loads, worker pool allocations, and batch parameters to predict latency and shedding rates.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),

            // Controls
            _buildSliderCard(
              label: 'TRAFFIC RATE (EVENTS/MIN)',
              valueStr: '${_trafficRate.toInt()} e/min',
              value: _trafficRate,
              min: 1000,
              max: 30000,
              divisions: 29,
              onChanged: (val) => setState(() => _trafficRate = val),
            ),
            const SizedBox(height: 10),
            _buildSliderCard(
              label: 'WORKER POOL COUNT',
              valueStr: '${_workerCount.toInt()} workers',
              value: _workerCount,
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: (val) => setState(() => _workerCount = val),
            ),
            const SizedBox(height: 10),
            _buildSliderCard(
              label: 'P3 LOG BATCH SIZE',
              valueStr: '${_batchSize.toInt()} events',
              value: _batchSize,
              min: 10,
              max: 1000,
              divisions: 99,
              onChanged: (val) => setState(() => _batchSize = val),
            ),
            const SizedBox(height: 10),
            _buildSliderCard(
              label: 'BASE PROCESSING COST',
              valueStr: '${_processingCostMs.toInt()} ms',
              value: _processingCostMs,
              min: 5,
              max: 200,
              divisions: 39,
              onChanged: (val) => setState(() => _processingCostMs = val),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.agent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() => _hasSimulated = true);
                },
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('RUN SCENARIO SIMULATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 20),

            if (_hasSimulated) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.agent.withOpacity(0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SIMULATED PREDICTION RESULT',
                          style: TextStyle(color: AppColors.agentGlow, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.agent.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: const Text('PREDICTED MODEL', style: TextStyle(color: AppColors.agentGlow, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildOutputItem('P0 Latency', '48 ms', AppColors.healthy),
                        _buildOutputItem('P1 Latency', '72 ms', AppColors.healthy),
                        _buildOutputItem('P2 Latency', '320 ms', AppColors.warning),
                        _buildOutputItem('P3 Latency', '1.2 s', AppColors.warning),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('CRITICAL EVENTS LOST:', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        const Text('0 (100% PROTECTED)', style: TextStyle(color: AppColors.healthy, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('EXPECTED NON-CRITICAL SHEDDING:', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        Text('${((_trafficRate / 30000) * 12).toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSliderCard({
    required String label,
    required String valueStr,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(valueStr, style: const TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppColors.info,
            inactiveColor: AppColors.surfaceElevated,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildOutputItem(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
