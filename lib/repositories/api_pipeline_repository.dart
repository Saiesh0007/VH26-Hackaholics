import 'package:dio/dio.dart';
import 'pipeline_repository.dart';
import '../models/event.dart';
import '../models/pipeline_metrics.dart';
import '../models/queue_metrics.dart';
import '../models/pipeline_policy.dart';
import '../models/processing_decision.dart';
import '../models/agent_state.dart';
import '../models/incident.dart';
import '../models/simulation_config.dart';

class ApiPipelineRepository implements PipelineRepository {
  final Dio dio;
  final String baseUrl;

  ApiPipelineRepository({
    Dio? dio,
    this.baseUrl = 'http://localhost:8000/api/v1',
  }) : dio = dio ?? Dio();

  @override
  Future<PipelineMetrics> getMetrics() async {
    await dio.get('$baseUrl/metrics');
    return PipelineMetrics.initial(); // Standard mock deserialization fallback
  }

  @override
  Future<List<PriorityQueueMetrics>> getQueues() async {
    await dio.get('$baseUrl/queues');
    return [];
  }

  @override
  Future<List<PipelineEvent>> getRecentEvents() async {
    await dio.get('$baseUrl/events');
    return [];
  }

  @override
  Future<List<ProcessingDecision>> getDecisions() async {
    await dio.get('$baseUrl/decisions');
    return [];
  }

  @override
  Future<PipelinePolicy> getCurrentPolicy() async {
    await dio.get('$baseUrl/policy');
    return PipelinePolicy.defaultPolicy();
  }

  @override
  Future<List<SystemIncident>> getIncidents() async {
    await dio.get('$baseUrl/incidents');
    return [];
  }

  @override
  Future<AgentStateSummary> getAgentState() async {
    await dio.get('$baseUrl/agent/state');
    return AgentStateSummary.initial();
  }

  @override
  Future<void> triggerSpike() async {
    await dio.post('$baseUrl/simulation/spike');
  }

  @override
  Future<void> recover() async {
    await dio.post('$baseUrl/simulation/recover');
  }

  @override
  Future<void> applyPolicy(PipelinePolicy policy) async {
    await dio.post('$baseUrl/agent/policy');
  }

  @override
  Future<void> rollbackPolicy() async {
    await dio.post('$baseUrl/agent/rollback');
  }

  @override
  Future<void> updateSimulationConfig(SimulationConfig config) async {
    await dio.post('$baseUrl/simulation/config');
  }
}
