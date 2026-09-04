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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FLOWMIND CONTROL CENTER', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text('Autonomous AI Pipeline Intelligence Engine', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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

                // Current Objective Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.agent.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CURRENT OBJECTIVE',
                        style: TextStyle(color: AppColors.agentGlow, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        agentSummary.currentObjective,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 8),
                      Text(
                        'Condition: ${agentSummary.currentCondition}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Current Action & Rollback Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ACTIVE POLICY ACTION',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        foregroundColor: AppColors.warning,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () {
                        ref.read(pipelineRepositoryProvider).rollbackPolicy();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ROLLBACK EXECUTED: Policy reverted to previous state.')),
                        );
                      },
                      icon: const Icon(Icons.undo, size: 14),
                      label: const Text('ROLLBACK POLICY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
                    style: const TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 18),

                // Recent AI Decisions Feed
                const Text(
                  'RECENT AGENT DECISIONS',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 10),

                decisionsAsync.when(
                  data: (decisions) {
                    if (decisions.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No policy changes recorded yet.', style: TextStyle(color: AppColors.textMuted)),
                      );
                    }
                    return Column(
                      children: decisions.take(5).map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DecisionCard(decision: d),
                      )).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 18),

                // FlowMind Activity Timeline
                const Text(
                  'AGENT ACTIVITY TIMELINE',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
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
                    children: engine.agent.activityTimeline.take(8).map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        entry,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'monospace'),
                      ),
                    )).toList(),
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
