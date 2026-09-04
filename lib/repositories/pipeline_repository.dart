import '../models/event.dart';
import '../models/pipeline_metrics.dart';
import '../models/queue_metrics.dart';
import '../models/pipeline_policy.dart';
import '../models/processing_decision.dart';
import '../models/agent_state.dart';
import '../models/incident.dart';
import '../models/simulation_config.dart';

abstract class PipelineRepository {
  Future<PipelineMetrics> getMetrics();
  Future<List<PriorityQueueMetrics>> getQueues();
  Future<List<PipelineEvent>> getRecentEvents();
  Future<List<ProcessingDecision>> getDecisions();
  Future<PipelinePolicy> getCurrentPolicy();
  Future<List<SystemIncident>> getIncidents();
  Future<AgentStateSummary> getAgentState();

  Future<void> triggerSpike();
  Future<void> recover();
  Future<void> setTrafficRate(int ratePerMin);
  Future<void> applyPolicy(PipelinePolicy policy);
  Future<void> rollbackPolicy();
  Future<void> updateSimulationConfig(SimulationConfig config);
}
