import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PolicyHistoryScreen extends StatelessWidget {
  const PolicyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POLICY ADAPTATION HISTORY', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPolicyHistoryCard(
            policyId: 'POLICY #018',
            timestamp: '09:43:12',
            p2Change: 'STREAM → BATCH (250)',
            p3Change: 'BATCH → SAMPLE (20% retained)',
            trigger: '20× Traffic Surge (20,000 e/min)',
            result: 'P0 latency remained safe at 48ms; P3 queue growth reduced by 82%',
            status: 'SUCCESS',
            isSuccess: true,
          ),
          _buildPolicyHistoryCard(
            policyId: 'POLICY #017',
            timestamp: '09:42:45',
            p2Change: 'STREAM → MICRO-BATCH (100)',
            p3Change: 'STREAM → BATCH (250)',
            trigger: 'Elevated traffic anomaly detected (8,500 e/min)',
            result: 'Worker CPU utilization stabilized at 68%',
            status: 'SUCCESS',
            isSuccess: true,
          ),
          _buildPolicyHistoryCard(
            policyId: 'POLICY #016',
            timestamp: '09:40:10',
            p2Change: 'STREAM',
            p3Change: 'STREAM',
            trigger: 'Normal baseline operation (1,000 e/min)',
            result: 'Baseline operations active; low queue pressure',
            status: 'STABLE',
            isSuccess: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyHistoryCard({
    required String policyId,
    required String timestamp,
    required String p2Change,
    required String p3Change,
    required String trigger,
    required String result,
    required String status,
    required bool isSuccess,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Text(policyId, style: const TextStyle(color: AppColors.agentGlow, fontSize: 13, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isSuccess ? AppColors.healthy : AppColors.warning).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('✓ $status', style: TextStyle(color: isSuccess ? AppColors.healthy : AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Trigger: $trigger', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('P2 Activity: $p2Change', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          Text('P3 Logs: $p3Change', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 6),
          Text('Result: $result', style: const TextStyle(color: AppColors.healthy, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
