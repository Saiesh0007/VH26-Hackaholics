import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/domain_policy.dart';
import '../../core/constraints/policy_validator.dart';
import '../../providers/domain_provider.dart';
import 'policy_editor_dialog.dart';

class CreatePipelineScreen extends ConsumerStatefulWidget {
  const CreatePipelineScreen({super.key});

  @override
  ConsumerState<CreatePipelineScreen> createState() => _CreatePipelineScreenState();
}

class _CreatePipelineScreenState extends ConsumerState<CreatePipelineScreen> {
  final TextEditingController _promptController = TextEditingController();

  bool _isGenerating = false;
  int _analysisStep = 0;
  DomainPolicy? _generatedPolicy;
  PolicyValidationResult? _validationResult;

  final List<String> _analysisSteps = [
    'Domain identified',
    'Event types identified',
    'Critical events identified',
    'Priority policy generated',
    'SLA profiles generated',
    'Batching rules generated',
    'Shedding policy generated',
  ];

  final List<Map<String, String>> _samplePresets = [
    {
      'title': '🏥 Hospital Disaster Response',
      'prompt':
          'A hospital emergency department is dealing with a disaster. Emergency patient alerts and ambulance arrivals must be processed immediately with zero drops. ICU availability and medical inventory are important but can tolerate a small delay. Routine reports, analytics and logs can be delayed or sampled.',
    },
    {
      'title': '🎓 University Result Publishing',
      'prompt':
          'University publishing semester results to 50,000 students simultaneously. Result lookup and student authentication must be immediate. Fee payment verification is high priority. Score notifications, logs, and analytics can be queued, batched, or deferred.',
    },
    {
      'title': '🚗 Urban Fleet & Transit Dispatch',
      'prompt':
          'Fleet management platform under extreme peak hours. SOS passenger emergency alerts and vehicle collision telemetry must never be dropped. Ride matching and fare transactions need fast SLAs. Vehicle battery telemetry and routine trip analytics can be batched and sampled.',
    },
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generatePolicy() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _analysisStep = 0;
      _generatedPolicy = null;
      _validationResult = null;
    });

    // Simulate animated step transitions for realistic AI analysis feedback
    for (int i = 0; i < _analysisSteps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        setState(() {
          _analysisStep = i + 1;
        });
      }
    }

    final aiService = ref.read(aiDomainServiceProvider);
    final policy = await aiService.generatePolicy(prompt);
    final validation = await aiService.validatePolicy(policy);

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _generatedPolicy = policy;
        _validationResult = validation;
      });
    }
  }

  void _deployPolicy() {
    if (_generatedPolicy == null) return;
    if (_validationResult != null && !_validationResult!.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot deploy policy: Validation errors must be resolved first.'),
          backgroundColor: AppColors.critical,
        ),
      );
      return;
    }

    ref.read(domainProvider.notifier).addAndActivatePolicy(_generatedPolicy!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Domain Policy "${_generatedPolicy!.domainName}" activated in AdaptQ!'),
        backgroundColor: AppColors.healthy,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'AI DOMAIN ARCHITECT',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.0),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Title
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
                    'CREATE YOUR ADAPTIVE PIPELINE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Describe your target domain in natural language. Gemini AI will synthesize an operational domain policy with priority tiers, strict SLAs, and shedding rules. Human approval is strictly required before activation.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // Prompt input
                  TextField(
                    controller: _promptController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. University publishing semester results to 50,000 students simultaneously...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quick presets
                  const Text(
                    'QUICK SCENARIO PRESETS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _samplePresets.map((preset) {
                      return ActionChip(
                        label: Text(preset['title']!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        backgroundColor: AppColors.surfaceElevated,
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onPressed: () {
                          _promptController.text = preset['prompt']!;
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(
                        _isGenerating ? 'AI SYNTHESIZING POLICY...' : '✨ GENERATE ADAPTIVE POLICY',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.8),
                      ),
                      onPressed: _isGenerating ? null : _generatePolicy,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // AI Analyzing Steps Animation
            if (_isGenerating || _analysisStep > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.hub_rounded, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'AI ANALYZING DOMAIN...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_analysisSteps.length, (index) {
                      final isDone = index < _analysisStep;
                      final isCurrent = index == _analysisStep - 1;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Icon(
                              isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              size: 15,
                              color: isDone
                                  ? AppColors.healthy
                                  : (isCurrent ? AppColors.primary : AppColors.textMuted),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _analysisSteps[index],
                              style: TextStyle(
                                fontSize: 12,
                                color: isDone ? AppColors.textPrimary : AppColors.textMuted,
                                fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Human Approval & Review Card
            if (_generatedPolicy != null) ...[
              _buildApprovalCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard() {
    final policy = _generatedPolicy!;
    final validation = _validationResult ?? DartPolicyValidator.validate(policy);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: validation.isValid ? AppColors.healthy.withOpacity(0.5) : AppColors.critical,
          width: 1.2,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'AI GENERATED PIPELINE POLICY',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryLight),
                ),
              ),
              // Validation Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: validation.isValid
                      ? AppColors.healthy.withOpacity(0.15)
                      : AppColors.critical.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      validation.isValid ? Icons.verified_rounded : Icons.error_outline_rounded,
                      size: 13,
                      color: validation.isValid ? AppColors.healthy : AppColors.critical,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      validation.isValid ? 'Deterministic Validation: PASSED' : 'Validation: FAILED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: validation.isValid ? AppColors.healthy : AppColors.critical,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            policy.domainName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            policy.description,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),

          const Text(
            'SYNTHESIZED EVENT TIERS & PROCESSING RULES',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),

          // Event type cards
          ...policy.eventTypes.map((evt) => _buildEventPolicyItem(evt)),

          if (!validation.isValid) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.critical.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.critical.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('POLICY SAFETY VIOLATIONS (Activation Blocked):',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.critical)),
                  const SizedBox(height: 4),
                  ...validation.errors.map((e) => Text('• $e', style: const TextStyle(fontSize: 11, color: AppColors.critical))),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Action Buttons: EDIT POLICY & ACCEPT & DEPLOY
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('EDIT POLICY', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () {
                    PolicyEditorDialog.show(
                      context,
                      initialPolicy: _generatedPolicy!,
                      onSave: (updated) {
                        setState(() {
                          _generatedPolicy = updated;
                          _validationResult = DartPolicyValidator.validate(updated);
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: validation.isValid ? AppColors.healthy : AppColors.surfaceElevated,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('ACCEPT & DEPLOY', style: TextStyle(fontWeight: FontWeight.w800)),
                  onPressed: validation.isValid ? _deployPolicy : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventPolicyItem(EventPolicy evt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: evt.isCritical ? AppColors.critical.withOpacity(0.3) : AppColors.cardBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Priority Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: evt.isCritical
                  ? AppColors.critical.withOpacity(0.18)
                  : AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              evt.priority,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: evt.isCritical ? AppColors.critical : AppColors.primaryLight,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evt.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  '${evt.preferredStrategy.toUpperCase()} • SLA: ${evt.slaMs}ms ${evt.isBatchable ? "• MaxBatch: ${evt.maxBatchSize}" : ""}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Sheddable / Critical tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: evt.isCritical
                  ? AppColors.critical.withOpacity(0.12)
                  : (evt.canShed ? AppColors.warning.withOpacity(0.12) : AppColors.surface),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              evt.isCritical ? 'NEVER DROP' : (evt.canShed ? 'SHEDDABLE' : 'PROTECTED'),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: evt.isCritical
                    ? AppColors.critical
                    : (evt.canShed ? AppColors.warning : AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
