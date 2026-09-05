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
    this.baseUrl = 'http://192.168.137.115:8000/api/v1',
  }) : dio = dio ?? Dio();

  @override
  Future<PipelineMetrics> getMetrics() async {
    final response = await dio.get('$baseUrl/metrics');
    final data = Map<String, dynamic>.from(response.data as Map);
    return PipelineMetrics(
      eventRatePerMin: (data['eventRatePerMin'] as num?)?.toInt() ?? 1000,
      throughputPerSec: (data['throughputPerSec'] as num?)?.toInt() ?? 0,
      systemLoadPercentage:
          (data['systemLoadPercentage'] as num?)?.toDouble() ?? 0,
      queuePressurePercentage:
          (data['queuePressurePercentage'] as num?)?.toDouble() ?? 0,
      p0LatencyMs: (data['p0LatencyMs'] as num?)?.toDouble() ?? 0,
      p1LatencyMs: (data['p1LatencyMs'] as num?)?.toDouble() ?? 0,
      p2LatencyMs: (data['p2LatencyMs'] as num?)?.toDouble() ?? 0,
      p3LatencyMs: (data['p3LatencyMs'] as num?)?.toDouble() ?? 0,
      criticalEventsLost: (data['criticalEventsLost'] as num?)?.toInt() ?? 0,
      totalDeferredCount: (data['totalDeferredCount'] as num?)?.toInt() ?? 0,
      totalShedCount: (data['totalShedCount'] as num?)?.toInt() ?? 0,
      workerUtilization: (data['workerUtilization'] as num?)?.toDouble() ?? 0,
      timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
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
  Future<void> setTrafficRate(int ratePerMin) async {
    await dio.post(
      '$baseUrl/simulation/config',
      data: {'trafficRatePerMin': ratePerMin},
    );
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
