import 'package:flutter/material.dart';
import '../../models/domain_policy.dart';
import '../../core/constraints/policy_validator.dart';
import '../../core/theme/app_colors.dart';

class PolicyEditorDialog extends StatefulWidget {
  final DomainPolicy initialPolicy;
  final Function(DomainPolicy updatedPolicy) onSave;

  const PolicyEditorDialog({
    super.key,
    required this.initialPolicy,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required DomainPolicy initialPolicy,
    required Function(DomainPolicy updatedPolicy) onSave,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => PolicyEditorDialog(
        initialPolicy: initialPolicy,
        onSave: onSave,
      ),
    );
  }

  @override
  State<PolicyEditorDialog> createState() => _PolicyEditorDialogState();
}

class _PolicyEditorDialogState extends State<PolicyEditorDialog> {
  late TextEditingController _domainNameController;
  late TextEditingController _descriptionController;
  late List<EventPolicy> _eventTypes;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _domainNameController =
        TextEditingController(text: widget.initialPolicy.domainName);
    _descriptionController =
        TextEditingController(text: widget.initialPolicy.description);
    _eventTypes = List<EventPolicy>.from(widget.initialPolicy.eventTypes);
  }

  @override
  void dispose() {
    _domainNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateEvent(int index, EventPolicy updated) {
    setState(() {
      _eventTypes[index] = updated;
      _validate();
    });
  }

  void _validate() {
    final candidate = DomainPolicy(
      domainName: _domainNameController.text.trim(),
      description: _descriptionController.text.trim(),
      eventTypes: _eventTypes,
      priorityTiers: widget.initialPolicy.priorityTiers,
      globalSettings: widget.initialPolicy.globalSettings,
    );
    final result = DartPolicyValidator.validate(candidate);
    setState(() {
      _validationError = result.isValid ? null : result.errors.join('\n');
    });
  }

  void _handleSave() {
    final candidate = DomainPolicy(
      domainName: _domainNameController.text.trim(),
      description: _descriptionController.text.trim(),
      eventTypes: _eventTypes,
      priorityTiers: widget.initialPolicy.priorityTiers,
      globalSettings: widget.initialPolicy.globalSettings,
    );

    final result = DartPolicyValidator.validate(candidate);
    if (!result.isValid) {
      setState(() {
        _validationError = result.errors.join('\n');
      });
      return;
    }

    widget.onSave(candidate);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final maxWidth = (viewport.width - 32).clamp(0.0, 650.0).toDouble();
    final maxHeight = (viewport.height - 32).clamp(320.0, 600.0).toDouble();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      child: SizedBox(
        width: maxWidth,
        height: maxHeight.clamp(320.0, 600.0),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune_rounded,
                          color: AppColors.primary, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'EDIT DOMAIN POLICY',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Domain Name input
              TextField(
                controller: _domainNameController,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Domain Name',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _validate(),
              ),
              const SizedBox(height: 16),

              const Text(
                'CONFIGURED EVENT TIERS',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),

              // Events List
              Expanded(
                child: ListView.separated(
                  itemCount: _eventTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final evt = _eventTypes[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.cardBorder, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  evt.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.textPrimary),
                                ),
                              ),
                              // Priority Dropdown
                              DropdownButton<String>(
                                value: evt.priority,
                                dropdownColor: AppColors.surfaceElevated,
                                underline: const SizedBox.shrink(),
                                items: ['P0', 'P1', 'P2', 'P3'].map((p) {
                                  return DropdownMenuItem(
                                    value: p,
                                    child: Text(p,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)),
                                  );
                                }).toList(),
                                onChanged: (newP) {
                                  if (newP != null) {
                                    _updateEvent(
                                      index,
                                      evt.copyWith(
                                        priority: newP,
                                        isCritical: newP == 'P0',
                                        canShed:
                                            newP == 'P0' ? false : evt.canShed,
                                        canDefer:
                                            newP == 'P0' ? false : evt.canDefer,
                                      ),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              // Strategy Dropdown
                              DropdownButton<String>(
                                value: evt.preferredStrategy,
                                dropdownColor: AppColors.surfaceElevated,
                                underline: const SizedBox.shrink(),
                                items: [
                                  'stream',
                                  'micro_batch',
                                  'batch',
                                  'defer'
                                ].map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Text(s.toUpperCase(),
                                        style: const TextStyle(fontSize: 11)),
                                  );
                                }).toList(),
                                onChanged: (newS) {
                                  if (newS != null) {
                                    _updateEvent(index,
                                        evt.copyWith(preferredStrategy: newS));
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'SLA: ${evt.slaMs}ms',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                              const Spacer(),
                              // Sheddable toggle
                              if (!evt.isCritical) ...[
                                Row(
                                  children: [
                                    const Text('Sheddable:',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted)),
                                    Switch(
                                      value: evt.canShed,
                                      activeColor: AppColors.warning,
                                      onChanged: (val) {
                                        _updateEvent(
                                          index,
                                          evt.copyWith(
                                            canShed: val,
                                            sheddingThreshold: val ? 0.75 : 0.0,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.critical.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'NEVER DROP (CRITICAL)',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.critical),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              if (_validationError != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.critical.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppColors.critical.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.critical, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _validationError!,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.critical,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _handleSave,
                    child: const Text('Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
