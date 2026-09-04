import 'pipeline_repository.dart';
import '../simulation/simulation_engine.dart';
import '../models/event.dart';
import '../models/pipeline_metrics.dart';
import '../models/queue_metrics.dart';
import '../models/pipeline_policy.dart';
import '../models/processing_decision.dart';
import '../models/agent_state.dart';
import '../models/incident.dart';
import '../models/simulation_config.dart';

class MockPipelineRepository implements PipelineRepository {
  final SimulationEngine simulationEngine;

  MockPipelineRepository(this.simulationEngine);

  @override
  Future<PipelineMetrics> getMetrics() async {
    return simulationEngine.runtime.tickSimulation();
  }

  @override
  Future<List<PriorityQueueMetrics>> getQueues() async {
    final metrics = await getMetrics();
    return simulationEngine.runtime.getQueueMetricsList(metrics);
  }

  @override
  Future<List<PipelineEvent>> getRecentEvents() async {
    return simulationEngine.runtime.recentEvents;
  }

  @override
  Future<List<ProcessingDecision>> getDecisions() async {
    return simulationEngine.agent.decisionsHistory;
  }

  @override
  Future<PipelinePolicy> getCurrentPolicy() async {
    return simulationEngine.runtime.activePolicy;
  }

  @override
  Future<List<SystemIncident>> getIncidents() async {
    return simulationEngine.incidents;
  }

  @override
  Future<AgentStateSummary> getAgentState() async {
    return simulationEngine.agent.summary;
  }

  @override
  Future<void> triggerSpike() async {
    simulationEngine.trigger20xSpike();
  }

  @override
  Future<void> recover() async {
    simulationEngine.recoverToNormal();
  }

  @override
  Future<void> setTrafficRate(int ratePerMin) async {
    simulationEngine.setTrafficRate(ratePerMin);
  }

  @override
  Future<void> applyPolicy(PipelinePolicy policy) async {
    simulationEngine.runtime.setPolicy(policy);
  }

  @override
  Future<void> rollbackPolicy() async {
    simulationEngine.agent.rollbackPolicy(simulationEngine.runtime);
  }

  @override
  Future<void> updateSimulationConfig(SimulationConfig config) async {
    simulationEngine.updateConfig(config);
  }
}
