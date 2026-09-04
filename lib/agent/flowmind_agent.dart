import '../models/agent_state.dart';
import '../models/event.dart';
import '../models/pipeline_metrics.dart';
import '../models/pipeline_policy.dart';
import '../models/processing_decision.dart';
import 'safety_guard.dart';
import 'agent_memory.dart';
import 'optimizer_agent.dart';
import 'evaluator_agent.dart';
import '../simulation/pipeline_runtime.dart';
import '../core/constants/app_constants.dart';

class FlowMindAgent {
  final SafetyGuard safetyGuard = SafetyGuard();
  final AgentMemory agentMemory = AgentMemory();
  final OptimizerAgent optimizer = OptimizerAgent();
  final EvaluatorAgent evaluator = EvaluatorAgent();

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
    _logTimeline('OBSERVE: Traffic ${metrics.eventRatePerMin} e/min | Load ${metrics.systemLoadPercentage.toInt()}% | P0 Latency ${metrics.p0LatencyMs.toInt()}ms');

    // PHASE 1: EVALUATOR AGENT AUDIT (Comparative Analysis & Rollback Check)
    final didRollback = evaluator.evaluateAndAudit(runtime, metrics);
    if (didRollback) {
      _currentState = FlowMindState.warning;
      _activeActionDescription = evaluator.latestVerdict;
      _logTimeline('EVALUATOR AGENT ROLLBACK: Suboptimal constraints reverted to prior state.');
      return;
    }

    // PHASE 2: HEALTH & CONDITION ASSESSMENT
    final multiplier = (metrics.eventRatePerMin / 1000).round();
    if (metrics.eventRatePerMin >= 15000) {
      _currentState = FlowMindState.warning;
      _currentCondition = 'CRITICAL SURGE: ${multiplier}× Traffic Surge Active (${metrics.eventRatePerMin} e/min)';
      _currentObjective = 'PROTECT P0 PAYMENTS/ORDERS; Dynamic constraint tuning active';
    } else if (metrics.eventRatePerMin > 3000) {
      _currentState = FlowMindState.analyzing;
      _currentCondition = 'ELEVATED TRAFFIC: ${multiplier}× Moderate surge (${metrics.eventRatePerMin} e/min)';
      _currentObjective = 'Optimizer dynamically tuning batch & worker allocations';
    } else {
      if (_currentState != FlowMindState.stable) {
        _currentState = FlowMindState.recovering;
        _currentCondition = 'RECOVERY: Traffic normalizing (${metrics.eventRatePerMin} e/min)';
        _currentObjective = 'Restoring baseline streaming constraints';
      }
    }

    // PHASE 3: OPTIMIZER AGENT ANALYZES METRICS & TUNES CONSTRAINTS
    final candidatePolicy = optimizer.analyzeAndTuneConstraints(
      runtime: runtime,
      metrics: metrics,
      evaluator: evaluator,
    );

    if (candidatePolicy != null) {
      _currentState = FlowMindState.proposing;
      _logTimeline('OPTIMIZER PROPOSAL: ${candidatePolicy.reason}');

      // SafetyGuard Verification
      _currentState = FlowMindState.validating;
      final safetyCheck = safetyGuard.validatePolicy(candidatePolicy);

      if (safetyCheck.isApproved) {
        _currentState = FlowMindState.executing;
        _previousPolicy = runtime.activePolicy;
        runtime.setPolicy(candidatePolicy);
        _activeActionDescription = candidatePolicy.reason;
        _logTimeline('EXECUTE: New operational constraints applied.');

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

  void rollbackPolicy(PipelineRuntime runtime) {
    if (evaluator.activeCheckpoint != null) {
      evaluator.forceRollback(runtime);
      _logTimeline('MANUAL ROLLBACK: Reverted policy to checkpoint #${evaluator.activeCheckpoint?.id ?? "ORIGINAL"}');
      _activeActionDescription = 'Policy manually reverted to baseline checkpoint';
    } else if (_previousPolicy != null) {
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
