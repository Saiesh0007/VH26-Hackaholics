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
        title: const Text('SETTINGS & BACKEND CONFIG',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black,
                    border: Border.all(color: AppColors.cardBorder, width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3060A5FA),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AdaptQ Command Center',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Autonomous Pipeline Intelligence • v1.0.0',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                const Text('DATA SOURCE ENGINE',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('LOCAL MOCK SIMULATION',
                              style: TextStyle(fontSize: 10)),
                        ),
                        selected: settings.dataSource == DataSourceMode.mock,
                        onSelected: (_) =>
                            notifier.toggleDataSource(DataSourceMode.mock),
                        selectedColor: AppColors.info.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('FASTAPI BACKEND API',
                              style: TextStyle(fontSize: 10)),
                        ),
                        selected: settings.dataSource == DataSourceMode.api,
                        onSelected: (_) =>
                            notifier.toggleDataSource(DataSourceMode.api),
                        selectedColor: AppColors.info.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Active Endpoint: ${settings.backendUrl}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 14),
                const Text('BACKEND API URL (PC IP)',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: settings.backendUrl,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'http://192.168.137.115:8000/api/v1',
                    hintStyle: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  onChanged: (val) => notifier.setBackendUrl(val.trim()),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('Wi-Fi (192.168.137.115)',
                          style: TextStyle(
                              fontSize: 9, color: AppColors.textSecondary)),
                      backgroundColor: AppColors.surfaceElevated,
                      onPressed: () => notifier
                          .setBackendUrl('http://192.168.137.115:8000/api/v1'),
                    ),
                    ActionChip(
                      label: const Text('USB / Localhost',
                          style: TextStyle(
                              fontSize: 9, color: AppColors.textSecondary)),
                      backgroundColor: AppColors.surfaceElevated,
                      onPressed: () => notifier
                          .setBackendUrl('http://localhost:8000/api/v1'),
                    ),
                  ],
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
                  title: const Text('Haptic Feedback',
                      style: TextStyle(
                          color: AppColors.textPrimary, fontSize: 12)),
                  subtitle: const Text(
                      'Vibrate on policy changes and spike events',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  value: settings.hapticsEnabled,
                  activeColor: AppColors.info,
                  onChanged: notifier.toggleHaptics,
                ),
                const Divider(height: 1, color: AppColors.divider),
                SwitchListTile(
                  title: const Text('Particle Canvas Animations',
                      style: TextStyle(
                          color: AppColors.textPrimary, fontSize: 12)),
                  subtitle: const Text(
                      'Render 60 FPS live pipeline particle flow',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  value: settings.animationsEnabled,
                  activeColor: AppColors.healthy,
                  onChanged: notifier.toggleAnimations,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
