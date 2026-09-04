import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/domain_provider.dart';
import '../../providers/metrics_provider.dart';

class AiCopilotSheet extends ConsumerStatefulWidget {
  const AiCopilotSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AiCopilotSheet(),
    );
  }

  @override
  ConsumerState<AiCopilotSheet> createState() => _AiCopilotSheetState();
}

class _AiCopilotSheetState extends ConsumerState<AiCopilotSheet> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  Map<String, dynamic>? _copilotResponse;

  final List<String> _quickQuestions = [
    'Why are clicks being batched?',
    'Why was this event deferred?',
    'Why did AdaptQ scale workers?',
    'Why were logs shed?',
    'Why are payments protected during the spike?',
    'What would happen if traffic reaches 50,000 events/min?',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitQuestion(String query) async {
    if (query.trim().isEmpty) return;
    _promptController.text = query;
    setState(() {
      _isLoading = true;
      _copilotResponse = null;
    });

    final domainState = ref.read(domainProvider);
    final metricsAsync = ref.read(metricsStreamProvider);
    final metrics = metricsAsync.value;

    final metricsMap = <String, dynamic>{
      'events_per_minute': metrics?.eventRatePerMin ?? 1000,
      'total_queued_events': metrics != null ? (metrics.queuePressurePercentage * 50).toInt() : 120,
      'worker_utilization': metrics != null ? metrics.workerUtilization / 100.0 : 0.45,
      'critical_events_dropped': metrics?.criticalEventsLost ?? 0,
      'p0_latency_ms': metrics?.p0LatencyMs ?? 38.5,
      'active_workers': 8,
    };

    final aiService = ref.read(aiDomainServiceProvider);
    try {
      final res = await aiService.askCopilot(
        prompt: query,
        policy: domainState.activePolicy,
        metrics: metricsMap,
      );
      if (mounted) {
        setState(() {
          _copilotResponse = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final domainState = ref.watch(domainProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1.2),
          left: BorderSide(color: AppColors.cardBorder, width: 0.8),
          right: BorderSide(color: AppColors.cardBorder, width: 0.8),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ADAPTQ COPILOT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          'Domain: ${domainState.activePolicy.domainName}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.cardBorder, height: 1),

          // Content body
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                // Quick suggested prompts
                const Text(
                  'SUGGESTED REASONING QUERIES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickQuestions.map((q) {
                    return ActionChip(
                      label: Text(q, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      backgroundColor: AppColors.surfaceElevated,
                      side: const BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onPressed: () => _submitQuestion(q),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Loading State
                if (_isLoading)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(strokeWidth: 2.5),
                        SizedBox(height: 16),
                        Text(
                          'AI Copilot analyzing runtime context & active policy...',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                // AI Response with 4 explicit sections
                if (_copilotResponse != null) ...[
                  _buildSectionCard(
                    title: 'FACTS',
                    icon: Icons.info_outline_rounded,
                    color: AppColors.primaryLight,
                    content: _copilotResponse!['facts']?.toString() ?? '',
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    title: 'CURRENT METRICS',
                    icon: Icons.speed_rounded,
                    color: AppColors.primary,
                    content: _copilotResponse!['current_metrics']?.toString() ?? '',
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    title: 'POLICY',
                    icon: Icons.policy_rounded,
                    color: AppColors.warning,
                    content: _copilotResponse!['policy']?.toString() ?? '',
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    title: 'RECOMMENDATION',
                    icon: Icons.lightbulb_outline_rounded,
                    color: AppColors.healthy,
                    content: _copilotResponse!['recommendation']?.toString() ?? '',
                  ),
                ],
              ],
            ),
          ),

          // Bottom Prompt Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(top: BorderSide(color: AppColors.cardBorder, width: 0.8)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promptController,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ask Copilot about pipeline adaptation, latency, or shedding...',
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                      onSubmitted: _submitQuestion,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    onPressed: () => _submitQuestion(_promptController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
