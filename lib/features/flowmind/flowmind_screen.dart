import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/flowmind_provider.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/pipeline_provider.dart';
import '../../widgets/agent_status_indicator.dart';
import '../../widgets/decision_card.dart';
import '../../core/theme/app_colors.dart';
import 'policy_history_screen.dart';

class FlowMindScreen extends ConsumerWidget {
  const FlowMindScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentStateAsync = ref.watch(agentStateStreamProvider);
    final decisionsAsync = ref.watch(decisionsStreamProvider);
    final metricsAsync = ref.watch(metricsStreamProvider);
    final engine = ref.watch(simulationEngineProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black,
                border: Border.all(color: AppColors.cardBorder, width: 1.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FLOWMIND CONTROL CENTER',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text('Autonomous AI Pipeline Intelligence Engine',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.info),
            tooltip: 'Policy History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PolicyHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: agentStateAsync.when(
        data: (agentSummary) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Agent State Indicator
                AgentStatusIndicator(state: agentSummary.state),
                const SizedBox(height: 14),

                // Deterministic Classification Constraints Badge
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.info.withOpacity(0.4), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rule_rounded,
                            size: 16, color: AppColors.info),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CLASSIFICATION: DETERMINISTIC CONSTRAINTS',
                              style: TextStyle(
                                  color: AppColors.info,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Decoupled from AI. Zero-copy domain rules in classification_constraints.dart assign P0-P3 instantly.',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Dual-Agent Operational Matrix
                const Text(
                  'DUAL-AGENT AUTONOMOUS SYSTEM',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8),
                ),
                const SizedBox(height: 8),

                // Row with Agent 1 (Optimizer) and Agent 2 (Evaluator)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Agent 1: Optimizer Agent
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.agent.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.agent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'AGENT 1: OPTIMIZER',
                                    style: TextStyle(
                                        color: AppColors.agentGlow,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Status: ${engine.agent.optimizer.status.name.toUpperCase()}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Analyzes live telemetry & dynamically tunes batching, deferral, and worker constraints.',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 9.5),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'TUNINGS: ${engine.agent.optimizer.optimizationsCount}',
                                style: const TextStyle(
                                    color: AppColors.agentGlow,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Agent 2: Evaluator Agent
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.warning.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.warning,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'AGENT 2: EVALUATOR',
                                    style: TextStyle(
                                        color: AppColors.warning,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Audit: ${engine.agent.evaluator.status.name.toUpperCase()}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Compares before/after metrics. Autonomously reverts if proposals degrade SLAs.',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 9.5),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'AUTO-ROLLBACK: ACTIVE',
                                style: TextStyle(
                                    color: AppColors.healthy,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Evaluator Latest Verdict Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded,
                          size: 18, color: AppColors.agentGlow),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LATEST EVALUATOR AUDIT VERDICT',
                              style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              engine.agent.evaluator.latestVerdict,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Current Action & Rollback Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'ACTIVE POLICY ACTION',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        foregroundColor: AppColors.warning,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                      onPressed: () {
                        ref.read(pipelineRepositoryProvider).rollbackPolicy();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'ROLLBACK EXECUTED: Reverted to previous baseline checkpoint.')),
                        );
                      },
                      icon: const Icon(Icons.undo, size: 14),
                      label: const Text('MANUAL ROLLBACK',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    agentSummary.activeActionDescription,
                    style: const TextStyle(
                        color: AppColors.info,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 18),

                // Recent AI Decisions Feed
                const Text(
                  'RECENT AGENT DECISIONS',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8),
                ),
                const SizedBox(height: 10),

                decisionsAsync.when(
                  data: (decisions) {
                    if (decisions.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No policy changes recorded yet.',
                            style: TextStyle(color: AppColors.textMuted)),
                      );
                    }
                    return Column(
                      children: decisions
                          .take(5)
                          .map((d) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: DecisionCard(decision: d),
                              ))
                          .toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 18),

                // FlowMind Activity Timeline
                const Text(
                  'AGENT ACTIVITY TIMELINE',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: engine.agent.activityTimeline
                        .take(8)
                        .map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                entry,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontFamily: 'monospace'),
                              ),
                            ))
                        .toList(),
                  ),
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
