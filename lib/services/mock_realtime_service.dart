import 'pipeline_realtime_service.dart';
import '../simulation/simulation_engine.dart';
import '../models/pipeline_metrics.dart';
import '../models/queue_metrics.dart';
import '../models/event.dart';
import '../models/processing_decision.dart';
import '../models/agent_state.dart';

class MockPipelineRealtimeService implements PipelineRealtimeService {
  final SimulationEngine simulationEngine;

  MockPipelineRealtimeService(this.simulationEngine);

  @override
  Stream<PipelineMetrics> get metricsStream => simulationEngine.metricsStream;

  @override
  Stream<List<PriorityQueueMetrics>> get queuesStream => simulationEngine.queuesStream;

  @override
  Stream<List<PipelineEvent>> get eventsStream => simulationEngine.eventsStream;

  @override
  Stream<List<ProcessingDecision>> get decisionsStream => simulationEngine.decisionsStream;

  @override
  Stream<AgentStateSummary> get agentStateStream => simulationEngine.agentStateStream;

  @override
  void dispose() {
    // Controlled by engine
  }
}
