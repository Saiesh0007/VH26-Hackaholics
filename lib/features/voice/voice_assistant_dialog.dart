import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pipeline_provider.dart';
import '../../services/voice_assistant_service.dart';
import '../../core/theme/app_colors.dart';

class VoiceAssistantDialog extends ConsumerStatefulWidget {
  const VoiceAssistantDialog({super.key});

  @override
  ConsumerState<VoiceAssistantDialog> createState() => _VoiceAssistantDialogState();
}

class _VoiceAssistantDialogState extends ConsumerState<VoiceAssistantDialog> {
  final TextEditingController _textController = TextEditingController();
  VoiceResponse? _lastResponse;
  bool _isListening = false;

  void _handleCommand(String text) async {
    if (text.trim().isEmpty) return;
    final service = ref.read(voiceAssistantServiceProvider);
    final resp = await service.processQuery(text);
    setState(() {
      _lastResponse = resp;
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.agent, width: 1.5),
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
                const Row(
                  children: [
                    Icon(Icons.mic, color: AppColors.agent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'ASK FLOWMIND',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Ask questions about pipeline status or execute commands by voice or text.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 14),
            // Sample Voice Command Chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildPromptChip('🔥 Start flash sale'),
                _buildPromptChip('Why are you batching logs?'),
                _buildPromptChip('Are payments safe?'),
                _buildPromptChip('🟢 Recover system'),
              ],
            ),
            const SizedBox(height: 16),
            if (_lastResponse != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTION: ${_lastResponse!.actionTaken.toUpperCase()}',
                      style: const TextStyle(
                        color: AppColors.agentGlow,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _lastResponse!.textResponse,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Type voice command or query...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _handleCommand,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.agent,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.send, size: 16),
                  onPressed: () => _handleCommand(_textController.text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptChip(String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textPrimary)),
      backgroundColor: AppColors.surfaceElevated,
      side: const BorderSide(color: AppColors.cardBorder),
      onPressed: () => _handleCommand(label),
    );
  }
}
