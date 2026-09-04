import 'event.dart';

class ProcessingDecision {
  final String id;
  final DateTime timestamp;
  final WorkloadPriority targetPriority;
  final ProcessingStrategy action;
  final int batchSize;
  final String trigger;
  final String reason;
  final bool safetyValidated;
  final String safetyExplanation;
  final String agentState;
  final double expectedLatencyImpactMs;

  const ProcessingDecision({
    required this.id,
    required this.timestamp,
    required this.targetPriority,
    required this.action,
    required this.batchSize,
    required this.trigger,
    required this.reason,
    required this.safetyValidated,
    required this.safetyExplanation,
    required this.agentState,
    required this.expectedLatencyImpactMs,
  });
}
