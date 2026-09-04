import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../simulation/simulation_engine.dart';
import '../repositories/pipeline_repository.dart';
import '../repositories/mock_pipeline_repository.dart';
import '../services/pipeline_realtime_service.dart';
import '../services/mock_realtime_service.dart';
import '../services/copilot_service.dart';

final simulationEngineProvider = Provider<SimulationEngine>((ref) {
  final engine = SimulationEngine();
  engine.startSimulation();
  ref.onDispose(() => engine.dispose());
  return engine;
});

final pipelineRepositoryProvider = Provider<PipelineRepository>((ref) {
  final engine = ref.watch(simulationEngineProvider);
  return MockPipelineRepository(engine);
});

final pipelineRealtimeServiceProvider =
    Provider<PipelineRealtimeService>((ref) {
  final engine = ref.watch(simulationEngineProvider);
  return MockPipelineRealtimeService(engine);
});

final copilotServiceProvider = Provider<CopilotService>((ref) {
  return CopilotService();
});
