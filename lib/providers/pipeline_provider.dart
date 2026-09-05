import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../simulation/simulation_engine.dart';
import '../repositories/pipeline_repository.dart';
import '../repositories/mock_pipeline_repository.dart';
import '../repositories/api_pipeline_repository.dart';
import '../services/pipeline_realtime_service.dart';
import '../services/mock_realtime_service.dart';
import '../services/api_pipeline_realtime_service.dart';
import '../services/copilot_service.dart';
import 'settings_provider.dart';

final simulationEngineProvider = Provider<SimulationEngine>((ref) {
  final engine = SimulationEngine();
  engine.startSimulation();
  ref.onDispose(() => engine.dispose());
  return engine;
});

final pipelineRepositoryProvider = Provider<PipelineRepository>((ref) {
  final settings = ref.watch(settingsProvider);
  if (settings.dataSource == DataSourceMode.api) {
    return ApiPipelineRepository(baseUrl: settings.backendUrl);
  }
  final engine = ref.watch(simulationEngineProvider);
  return MockPipelineRepository(engine);
});

final pipelineRealtimeServiceProvider =
    Provider<PipelineRealtimeService>((ref) {
  final settings = ref.watch(settingsProvider);
  if (settings.dataSource == DataSourceMode.api) {
    final service = ApiPipelineRealtimeService(
      ApiPipelineRepository(baseUrl: settings.backendUrl),
    );
    ref.onDispose(service.dispose);
    return service;
  }
  final engine = ref.watch(simulationEngineProvider);
  return MockPipelineRealtimeService(engine);
});

final copilotServiceProvider = Provider<CopilotService>((ref) {
  return CopilotService();
});
