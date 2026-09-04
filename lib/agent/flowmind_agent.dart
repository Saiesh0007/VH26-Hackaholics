import '../models/agent_state.dart';
import '../models/event.dart';
import '../models/pipeline_metrics.dart';
import '../models/pipeline_policy.dart';
import '../models/processing_decision.dart';
import 'safety_guard.dart';
import 'agent_memory.dart';
import '../simulation/pipeline_runtime.dart';
import '../core/constants/app_constants.dart';

class FlowMindAgent {
  final SafetyGuard safetyGuard = SafetyGuard();
  final AgentMemory agentMemory = AgentMemory();

  FlowMindState _currentState = FlowMindState.stable;
  String _currentObjective = 'Protect critical workloads & maintain baseline latency';
  String _currentCondition = 'Normal traffic (~1,000 events/min)';
  String _activeActionDescription = 'Streaming mode active across all queues';

  final List<ProcessingDecision> _decisionsHistory = [];
  final List<String> _activityTimeline = [];
  PipelinePolicy? _previousPolicy;

  FlowMindState get currentState => _currentState;
  String get currentObjective => _currentObjective;
  String get currentCondition => _currentCondition;
  String get activeActionDescription => _activeActionDescription;
  List<ProcessingDecision> get decisionsHistory => List.unmodifiable(_decisionsHistory);
  List<String> get activityTimeline => List.unmodifiable(_activityTimeline);

  AgentStateSummary get summary => AgentStateSummary(
        state: _currentState,
        currentObjective: _currentObjective,
        currentCondition: _currentCondition,
        activeActionDescription: _activeActionDescription,
        lastStateChange: DateTime.now(),
      );

  /// FlowMind Autonomous Control Loop step called every simulation tick
  void runControlLoop(PipelineRuntime runtime, PipelineMetrics metrics) {
    _logTimeline('OBSERVE: Traffic ${metrics.eventRatePerMin} events/min | Load ${metrics.systemLoadPercentage.toInt()}% | P0 Latency ${metrics.p0LatencyMs.toInt()}ms');

    // Step 1: Detect Anomaly / Condition Assessment
    final multiplier = (metrics.eventRatePerMin / 1000).round();
    if (metrics.eventRatePerMin >= 15000) {
      _currentState = FlowMindState.warning;
      _currentCondition = 'CRITICAL SURGE: ${multiplier}× Traffic Surge Active (${metrics.eventRatePerMin} e/min)';
      _currentObjective = 'PROTECT P0 PAYMENTS/ORDERS; Mitigate queue saturation';
    } else if (metrics.eventRatePerMin > 3000) {
      _currentState = FlowMindState.analyzing;
      _currentCondition = 'ELEVATED TRAFFIC: ${multiplier}× Moderate surge (${metrics.eventRatePerMin} e/min)';
      _currentObjective = 'Prevent queue pressure spillover into P0 queues';
    } else {
      if (_currentState != FlowMindState.stable) {
        _currentState = FlowMindState.recovering;
        _currentCondition = 'RECOVERY: Traffic normalizing (${metrics.eventRatePerMin} e/min)';
        _currentObjective = 'Draining deferred queues & restoring streaming defaults';
      }
    }

    // Step 2 & 3: Reason & Formulate Candidate Policy
    final candidatePolicy = _formulatePolicy(runtime.activePolicy, metrics);

    if (candidatePolicy != null) {
      _currentState = FlowMindState.proposing;
      _logTimeline('PROPOSE: Formulated policy adaptation for queue pressure mitigation');

      // Step 4: Validate Policy with SafetyGuard
      _currentState = FlowMindState.validating;
      final safetyCheck = safetyGuard.validatePolicy(candidatePolicy);

      if (safetyCheck.isApproved) {
        _currentState = FlowMindState.executing;
        _previousPolicy = runtime.activePolicy;
        runtime.setPolicy(candidatePolicy);
        _activeActionDescription = candidatePolicy.reason;
        _logTimeline('EXECUTE: Policy applied successfully. ${candidatePolicy.reason}');

        // Record Decision
        _recordDecision(
          targetPriority: WorkloadPriority.p3Log,
          action: candidatePolicy.policies[WorkloadPriority.p3Log]!.mode,
          batchSize: candidatePolicy.policies[WorkloadPriority.p3Log]!.batchSize,
          trigger: 'Queue pressure ${metrics.queuePressurePercentage.toInt()}% under ${metrics.eventRatePerMin} e/min spike',
          reason: candidatePolicy.reason,
          safetyValidated: true,
          safetyExplanation: safetyCheck.explanation,
          expectedLatencyImpactMs: -25.0,
        );

        _currentState = FlowMindState.verifying;
      } else {
        _logTimeline('REJECTED BY SAFETY GUARD: ${safetyCheck.explanation}');
        _recordDecision(
          targetPriority: safetyCheck.violatedPriority ?? WorkloadPriority.p0Payment,
          action: ProcessingStrategy.shed,
          batchSize: 1,
          trigger: 'Attempted policy modification',
          reason: 'Attempted to alter critical workload strategy',
          safetyValidated: false,
          safetyExplanation: safetyCheck.explanation,
          expectedLatencyImpactMs: 0.0,
        );
        _currentState = FlowMindState.warning;
      }
    } else {
      if (metrics.eventRatePerMin < 2000 && _currentState == FlowMindState.recovering) {
        _currentState = FlowMindState.stable;
        _currentCondition = 'Normal traffic (~1,000 events/min)';
        _activeActionDescription = 'Streaming mode active across all queues';
        _logTimeline('STABLE: System fully recovered. Baseline policy active.');
      }
    }
  }

  PipelinePolicy? _formulatePolicy(PipelinePolicy currentPolicy, PipelineMetrics metrics) {
    final rate = metrics.eventRatePerMin;
    final pressure = metrics.queuePressurePercentage;

    // Standard baseline recovery
    if (rate <= 2000 && currentPolicy.policies[WorkloadPriority.p3Log]!.mode != ProcessingStrategy.stream) {
      return PipelinePolicy.defaultPolicy();
    }

    // Moderate spike (e.g. 5,000 - 15,000 e/min) -> Micro-batch P2 and P3
    if (rate > 3000 && rate < 15000) {
      if (currentPolicy.policies[WorkloadPriority.p2Activity]!.mode == ProcessingStrategy.stream) {
        final updated = Map<WorkloadPriority, PriorityPolicy>.from(currentPolicy.policies);
        updated[WorkloadPriority.p2Activity] = updated[WorkloadPriority.p2Activity]!.copyWith(
          mode: ProcessingStrategy.batch,
          batchSize: 250,
        );
        updated[WorkloadPriority.p3Log] = updated[WorkloadPriority.p3Log]!.copyWith(
          mode: ProcessingStrategy.batch,
          batchSize: 500,
        );

        return PipelinePolicy(
          policies: updated,
          timestamp: DateTime.now(),
          version: 'v2.1-microbatch',
          reason: 'Enable micro-batching for P2 Activity (250) and P3 Logs (500) to lower worker overhead.',
        );
      }
    }

    // Extreme spike (15,000+ e/min) -> Defer P2 Activity, Sample/Shed P3 Logs, KEEP P0 STREAMING
    if (rate >= 15000) {
      final p3Mode = currentPolicy.policies[WorkloadPriority.p3Log]!.mode;
      if (p3Mode != ProcessingStrategy.shed || pressure > 50) {
        final updated = Map<WorkloadPriority, PriorityPolicy>.from(currentPolicy.policies);
        
        // P0 Payments & Orders ALWAYS STREAMING
        updated[WorkloadPriority.p0Payment] = updated[WorkloadPriority.p0Payment]!.copyWith(
          mode: ProcessingStrategy.stream,
          workerCount: 12,
        );
        updated[WorkloadPriority.p0Order] = updated[WorkloadPriority.p0Order]!.copyWith(
          mode: ProcessingStrategy.stream,
          workerCount: 12,
        );

        // P1 Inventory Micro-batching
        updated[WorkloadPriority.p1Inventory] = updated[WorkloadPriority.p1Inventory]!.copyWith(
          mode: ProcessingStrategy.batch,
          batchSize: 100,
        );

        // P2 Activity Deferral
        updated[WorkloadPriority.p2Activity] = updated[WorkloadPriority.p2Activity]!.copyWith(
          mode: ProcessingStrategy.defer,
          deferWindowSeconds: 30,
        );

        // P3 Logs Sampling/Shedding
        updated[WorkloadPriority.p3Log] = updated[WorkloadPriority.p3Log]!.copyWith(
          mode: ProcessingStrategy.shed,
          samplingRate: 0.20, // Shed 80% of non-critical logs
        );

        return PipelinePolicy(
          policies: updated,
          timestamp: DateTime.now(),
          version: 'v3.0-extreme-surge',
          reason: '20× Surge Protection: Defer P2 Activity, Sample P3 Logs (80% shed), Stream P0 Payments/Orders.',
        );
      }
    }

    return null;
  }

  void rollbackPolicy(PipelineRuntime runtime) {
    if (_previousPolicy != null) {
      runtime.setPolicy(_previousPolicy!);
      _logTimeline('ROLLBACK: Reverted policy to previous version');
      _activeActionDescription = 'Policy rolled back due to user request';
    }
  }

  void _recordDecision({
    required WorkloadPriority targetPriority,
    required ProcessingStrategy action,
    required int batchSize,
    required String trigger,
    required String reason,
    required bool safetyValidated,
    required String safetyExplanation,
    required double expectedLatencyImpactMs,
  }) {
    final decision = ProcessingDecision(
      id: 'DEC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      timestamp: DateTime.now(),
      targetPriority: targetPriority,
      action: action,
      batchSize: batchSize,
      trigger: trigger,
      reason: reason,
      safetyValidated: safetyValidated,
      safetyExplanation: safetyExplanation,
      agentState: _currentState.label,
      expectedLatencyImpactMs: expectedLatencyImpactMs,
    );

    _decisionsHistory.insert(0, decision);
    if (_decisionsHistory.length > 50) {
      _decisionsHistory.removeLast();
    }
  }

  void _logTimeline(String entry) {
    final timeStr = DateTime.now().toIso8601String().substring(11, 19);
    _activityTimeline.insert(0, '[$timeStr] $entry');
    if (_activityTimeline.length > AppConstants.maxAgentLogSize) {
      _activityTimeline.removeLast();
    }
  }
}
