import '../models/pipeline_policy.dart';

class PolicyMemoryRecord {
  final String id;
  final DateTime timestamp;
  final int trafficLevelPerMin;
  final PipelinePolicy policy;
  final double resultingP0LatencyMs;
  final bool isSuccessful;
  final String outcomeDescription;

  const PolicyMemoryRecord({
    required this.id,
    required this.timestamp,
    required this.trafficLevelPerMin,
    required this.policy,
    required this.resultingP0LatencyMs,
    required this.isSuccessful,
    required this.outcomeDescription,
  });
}

class AgentMemory {
  final List<PolicyMemoryRecord> _history = [];

  List<PolicyMemoryRecord> get history => List.unmodifiable(_history);

  void recordOutcome(PolicyMemoryRecord record) {
    _history.insert(0, record);
    if (_history.length > 20) {
      _history.removeLast();
    }
  }

  PolicyMemoryRecord? findBestPolicyForTraffic(int trafficLevel) {
    final matches = _history.where((r) =>
        r.isSuccessful &&
        (r.trafficLevelPerMin - trafficLevel).abs() < 5000);
    if (matches.isEmpty) return null;
    return matches.first;
  }
}
