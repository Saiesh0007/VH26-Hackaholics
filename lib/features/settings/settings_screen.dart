import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS & BACKEND CONFIG', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DATA SOURCE ENGINE', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('LOCAL MOCK SIMULATION', style: TextStyle(fontSize: 10)),
                        selected: settings.dataSource == DataSourceMode.mock,
                        onSelected: (_) => notifier.toggleDataSource(DataSourceMode.mock),
                        selectedColor: AppColors.info.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('FASTAPI BACKEND API', style: TextStyle(fontSize: 10)),
                        selected: settings.dataSource == DataSourceMode.api,
                        onSelected: (_) => notifier.toggleDataSource(DataSourceMode.api),
                        selectedColor: AppColors.info.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Current Active Provider: ${settings.dataSource == DataSourceMode.mock ? 'MockPipelineRepository' : 'ApiPipelineRepository (http://localhost:8000)'}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Toggles
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Voice Assistant ("Ask FlowMind")', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                  subtitle: const Text('Enable voice commands and intelligent audio responses', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  value: settings.voiceAssistantEnabled,
                  activeColor: AppColors.agent,
                  onChanged: notifier.toggleVoiceAssistant,
                ),
                const Divider(height: 1, color: AppColors.divider),
                SwitchListTile(
                  title: const Text('Haptic Feedback', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                  subtitle: const Text('Vibrate on policy changes and spike events', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  value: settings.hapticsEnabled,
                  activeColor: AppColors.info,
                  onChanged: notifier.toggleHaptics,
                ),
                const Divider(height: 1, color: AppColors.divider),
                SwitchListTile(
                  title: const Text('Particle Canvas Animations', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                  subtitle: const Text('Render 60 FPS live pipeline particle flow', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  value: settings.animationsEnabled,
                  activeColor: AppColors.healthy,
                  onChanged: notifier.toggleAnimations,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
