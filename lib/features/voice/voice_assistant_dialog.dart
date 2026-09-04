import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pipeline_provider.dart';
import '../../services/voice_assistant_service.dart';
import '../../core/theme/app_colors.dart';

class VoiceAssistantDialog extends ConsumerStatefulWidget {
  const VoiceAssistantDialog({super.key});

  static Future<T?> show<T>(BuildContext context) {
    return showDialog<T>(
      context: context,
      builder: (_) => const VoiceAssistantDialog(),
    );
  }

  @override
  ConsumerState<VoiceAssistantDialog> createState() => _VoiceAssistantDialogState();
}

class _VoiceAssistantDialogState extends ConsumerState<VoiceAssistantDialog> {
  final TextEditingController _textController = TextEditingController();
  VoiceResponse? _lastResponse;
  bool _isListening = false;
  String? _listeningStatus;

  void _handleCommand(String text) async {
    if (text.trim().isEmpty) return;
    final service = ref.read(voiceAssistantServiceProvider);
    final resp = await service.processQuery(text);
    setState(() {
      _lastResponse = resp;
      _textController.clear();
      _isListening = false;
      _listeningStatus = null;
    });
  }

  void _toggleMic() async {
    if (_isListening) {
      setState(() {
        _isListening = false;
        _listeningStatus = null;
      });
      return;
    }

    setState(() {
      _isListening = true;
      _listeningStatus = 'Listening for speech input...';
    });

    // Simulate speech detection
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted && _isListening) {
      setState(() {
        _listeningStatus = 'Recognized: "Are payments safe under 100k surge?"';
      });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        _handleCommand('Are payments safe under 100k surge?');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.agent, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.agent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, color: AppColors.agent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ASK FLOWMIND',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Autonomous Natural Language Copilot',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Quick Prompt Chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildPromptChip('🔥 20k Surge', '20k spike'),
                _buildPromptChip('⚡ 60k Black Friday', '60k black friday'),
                _buildPromptChip('🚨 100k Stress Test', '100k extreme'),
                _buildPromptChip('🛡️ Payments safe?', 'Are payments safe?'),
                _buildPromptChip('📦 Why batch logs?', 'Why are you batching logs?'),
                _buildPromptChip('🟢 Baseline (1k)', 'recover to normal baseline'),
              ],
            ),
            const SizedBox(height: 16),

            // Active Listening or Response Banner
            if (_isListening) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.agent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.agent.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.graphic_eq_rounded, color: AppColors.agent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _listeningStatus ?? 'Listening...',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ] else if (_lastResponse != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ACTION: ${_lastResponse!.actionTaken.toUpperCase()}',
                          style: const TextStyle(
                            color: AppColors.agentGlow,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'ON-DEVICE PARSER',
                          style: TextStyle(color: AppColors.healthy, fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _lastResponse!.textResponse,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Input Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Ask FlowMind or command a surge level...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _handleCommand,
                  ),
                ),
                const SizedBox(width: 8),
                // Mic Button
                InkWell(
                  onTap: _toggleMic,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _isListening ? AppColors.critical : AppColors.agent.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: _isListening ? AppColors.critical : AppColors.agent, width: 1.0),
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                      size: 20,
                      color: _isListening ? Colors.white : AppColors.agentGlow,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Send Button
                InkWell(
                  onTap: () => _handleCommand(_textController.text),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, size: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // API Key Info Note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 13),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'No external API key needed: Intent parsing runs 100% locally on-device. Whisper API is only optional for custom cloud audio.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 9.5),
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

  Widget _buildPromptChip(String label, String command) {
    return InkWell(
      onTap: () => _handleCommand(command),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 0.8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
