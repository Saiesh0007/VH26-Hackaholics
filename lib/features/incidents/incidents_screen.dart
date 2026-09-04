import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pipeline_provider.dart';
import '../../providers/bland_ai_provider.dart';
import '../../models/incident.dart';
import '../../core/theme/app_colors.dart';
import 'emergency_call_dialog.dart';

class IncidentsScreen extends ConsumerStatefulWidget {
  const IncidentsScreen({super.key});

  @override
  ConsumerState<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends ConsumerState<IncidentsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    final blandService = ref.read(blandAiServiceProvider);
    _apiKeyController.text = blandService.apiKey ?? '';
    _phoneController.text = blandService.onCallPhoneNumber ?? '+18005550199';
  }

  void _showBlandAiConfigModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final blandService = ref.watch(blandAiServiceProvider);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BLAND AI EMERGENCY DISPATCH',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Autonomous phone calling agent for edge cases',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'BLAND AI API KEY',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _isObscured,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Enter Bland AI Key (e.g. org_... or sk-...)',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      suffixIcon: IconButton(
                        icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary, size: 18),
                        onPressed: () => setModalState(() => _isObscured = !_isObscured),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ON-CALL ENGINEER PHONE NUMBER',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: '+1XXXXXXXXXX or +91XXXXXXXXXX',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.phone, color: AppColors.textSecondary, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            await blandService.saveConfig(
                              apiKey: _apiKeyController.text,
                              phoneNumber: _phoneController.text,
                            );
                            if (mounted) Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bland AI settings saved.')),
                            );
                          },
                          child: const Text('SAVE CONFIG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            await blandService.saveConfig(
                              apiKey: _apiKeyController.text,
                              phoneNumber: _phoneController.text,
                            );
                            blandService.triggerEmergencyCall(
                              incidentTitle: 'TEST LIVE ESCALATION',
                              reason: 'Critical unhandled edge case at 100,000 e/min. P0 Latency ceiling breached.',
                              p0LatencyMs: 148.5,
                              trafficRate: 100000,
                            );
                            if (mounted) {
                              Navigator.pop(ctx);
                              EmergencyCallDialog.show(
                                context,
                                incidentTitle: 'CRITICAL EDGE CASE ESCALATION',
                                reason: 'Autonomous agent rollbacks failed to stabilize pipeline. P0 Latency ceiling breached.',
                                p0LatencyMs: 148.5,
                                trafficRate: 100000,
                              );
                            }
                          },
                          icon: const Icon(Icons.ring_volume_rounded, size: 16),
                          label: const Text(
                            'TRIGGER LIVE CALL',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '💡 Note: If API key is empty, Bland AI runs in Realistic Demo Mode with instant simulated dispatch logs.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(pipelineRepositoryProvider);
    final blandService = ref.watch(blandAiServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('INCIDENT & ESCALATION CENTER', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text('Automated SRE Triage & Bland AI Voice Dispatch', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bland AI Voice Dispatcher Hero Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              boxShadow: AppColors.orangeGlowShadow,
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BLAND AI EMERGENCY DISPATCH',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Autonomous voice call on unhandled edge cases',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.critical,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            EmergencyCallDialog.show(
                              context,
                              incidentTitle: 'UNRECOVERABLE PIPELINE EDGE CASE',
                              reason: 'Consecutive rollbacks failed to stabilize pipeline. P0 Latency ceiling breached at 148.5ms.',
                              p0LatencyMs: 148.5,
                              trafficRate: 100000,
                            );
                          },
                          icon: const Icon(Icons.ring_volume_rounded, size: 13),
                          label: const Text('RING PHONE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showBlandAiConfigModal(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.tune_rounded, size: 12, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text('SETUP', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'On-Call Target: ${blandService.onCallPhoneNumber ?? "+18005550199"}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (blandService.apiKey != null && blandService.apiKey!.isNotEmpty)
                            ? AppColors.healthy.withOpacity(0.15)
                            : AppColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (blandService.apiKey != null && blandService.apiKey!.isNotEmpty)
                            ? 'BLAND AI LIVE KEY READY'
                            : 'DEMO MODE (SIMULATED)',
                        style: TextStyle(
                          color: (blandService.apiKey != null && blandService.apiKey!.isNotEmpty)
                              ? AppColors.healthy
                              : AppColors.warning,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (blandService.latestCall != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'LATEST DISPATCH: #${blandService.latestCall!.callId}',
                              style: const TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              blandService.latestCall!.status,
                              style: const TextStyle(color: AppColors.healthy, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          blandService.latestCall!.reason,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'RECORDED INCIDENTS & AUDIT TRAIL',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<SystemIncident>>(
            future: repo.getIncidents(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final incidents = snapshot.data!;

              return Column(
                children: incidents.map((inc) {
                  Color color;
                  switch (inc.severity) {
                    case IncidentSeverity.critical:
                      color = AppColors.critical;
                      break;
                    case IncidentSeverity.warning:
                      color = AppColors.warning;
                      break;
                    default:
                      color = AppColors.healthy;
                      break;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(inc.title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                              child: Text(inc.status, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(inc.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        const SizedBox(height: 8),
                        Text(inc.timestamp.toIso8601String().substring(11, 19), style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
