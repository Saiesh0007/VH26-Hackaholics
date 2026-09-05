import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DataSourceMode {
  mock,
  api,
}

class AppSettings {
  final DataSourceMode dataSource;
  final String backendUrl;
  final bool hapticsEnabled;
  final bool audioAlertsEnabled;
  final bool animationsEnabled;

  const AppSettings({
    required this.dataSource,
    this.backendUrl = 'http://192.168.137.115:8000/api/v1',
    required this.hapticsEnabled,
    required this.audioAlertsEnabled,
    required this.animationsEnabled,
  });

  AppSettings copyWith({
    DataSourceMode? dataSource,
    String? backendUrl,
    bool? hapticsEnabled,
    bool? audioAlertsEnabled,
    bool? animationsEnabled,
  }) {
    return AppSettings(
      dataSource: dataSource ?? this.dataSource,
      backendUrl: backendUrl ?? this.backendUrl,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      audioAlertsEnabled: audioAlertsEnabled ?? this.audioAlertsEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier()
      : super(const AppSettings(
          dataSource: DataSourceMode.mock,
          backendUrl: 'http://192.168.137.115:8000/api/v1',
          hapticsEnabled: true,
          audioAlertsEnabled: true,
          animationsEnabled: true,
        ));

  void toggleDataSource(DataSourceMode mode) {
    state = state.copyWith(dataSource: mode);
  }

  void setBackendUrl(String url) {
    state = state.copyWith(backendUrl: url);
  }

  void toggleHaptics(bool enabled) {
    state = state.copyWith(hapticsEnabled: enabled);
  }

  void toggleAudioAlerts(bool enabled) {
    state = state.copyWith(audioAlertsEnabled: enabled);
  }

  void toggleAnimations(bool enabled) {
    state = state.copyWith(animationsEnabled: enabled);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
