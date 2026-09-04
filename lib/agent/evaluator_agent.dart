import '../models/pipeline_metrics.dart';
import '../models/pipeline_policy.dart';
import '../simulation/pipeline_runtime.dart';

/// Represents a stable checkpoint before the Optimizer Agent modifies constraints.
class StateCheckpoint {
  final String id;
  final PipelinePolicy policy;
  final PipelineMetrics metrics;
  final DateTime timestamp;
  final String triggerReason;

  const StateCheckpoint({
    required this.id,
    required this.policy,
    required this.metrics,
    required this.timestamp,
    required this.triggerReason,
  });
}

enum EvaluationStatus {
  idle,
  evaluating,
  approved,
  rolledBack,
}

class EvaluationAuditReport {
  final String id;
  final DateTime timestamp;
  final EvaluationStatus status;
  final double preP0LatencyMs;
  final double postP0LatencyMs;
  final double preQueuePressure;
  final double postQueuePressure;
  final String verdictDetails;
  final bool didRollback;

  const EvaluationAuditReport({
    required this.id,
    required this.timestamp,
    required this.status,
    required this.preP0LatencyMs,
    required this.postP0LatencyMs,
    required this.preQueuePressure,
    required this.postQueuePressure,
    required this.verdictDetails,
    required this.didRollback,
  });
}

/// Evaluator Agent (Supervisor Critic):
/// Analyzes the Optimizer Agent's decisions by comparing post-adjustment metrics
/// with the previous system checkpoint. If the proposed constraints degraded
/// system performance or breached critical business SLAs, it automatically
/// reverts the runtime to the previous state.
class EvaluatorAgent {
  StateCheckpoint? _activeCheckpoint;
  int _ticksObserved = 0;
  static const int _observationWindowTicks = 2; // Evaluate after 2-3 seconds

  EvaluationStatus _status = EvaluationStatus.idle;
  String _latestVerdict = 'Baseline verified. System within normal operational bounds.';
  final List<EvaluationAuditReport> _auditHistory = [];

  EvaluationStatus get status => _status;
  String get latestVerdict => _latestVerdict;
  StateCheckpoint? get activeCheckpoint => _activeCheckpoint;
  List<EvaluationAuditReport> get auditHistory => List.unmodifiable(_auditHistory);

  /// Capture a state checkpoint right before Optimizer modifies constraints.
  void captureCheckpoint({
    required PipelinePolicy policy,
    required PipelineMetrics metrics,
    required String reason,
  }) {
    _activeCheckpoint = StateCheckpoint(
      id: 'CPK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      policy: policy,
      metrics: metrics,
      timestamp: DateTime.now(),
      triggerReason: reason,
    );
    _ticksObserved = 0;
    _status = EvaluationStatus.evaluating;
    _latestVerdict = 'Evaluating Optimizer changes against checkpoint #${_activeCheckpoint!.id}...';
  }

  /// Evaluates the system metrics during each tick after Optimizer applied changes.
  /// If business metrics are suboptimal, automatically reverts to the original state.
  bool evaluateAndAudit(PipelineRuntime runtime, PipelineMetrics currentMetrics) {
    if (_activeCheckpoint == null || _status != EvaluationStatus.evaluating) {
      return false;
    }

    _ticksObserved++;
    if (_ticksObserved < _observationWindowTicks) {
      // Continue gathering data during observation window
      return false;
    }

    final pre = _activeCheckpoint!.metrics;
    final post = currentMetrics;

    // Comparative Metric Analysis
    final latencyDelta = post.p0LatencyMs - pre.p0LatencyMs;
    final isCriticalSlaBreached = post.p0LatencyMs > 75.0 || post.criticalEventsLost > 0;
    final isDegrading = latencyDelta > 20.0 && post.p0LatencyMs > 50.0;

    // Check if the business metrics suggested by Optimizer were suboptimal
    if (isCriticalSlaBreached || isDegrading) {
      // SUBOPTIMAL: Revert back to original state!
      runtime.setPolicy(_activeCheckpoint!.policy);
      _status = EvaluationStatus.rolledBack;

      final reason = isCriticalSlaBreached
          ? 'CRITICAL REVERT: P0 Latency reached ${post.p0LatencyMs.toStringAsFixed(1)}ms (exceeded 75ms ceiling). Auto-reverted to ${_activeCheckpoint!.id}.'
          : 'SUBOPTIMAL REVERT: P0 latency degraded by +${latencyDelta.toStringAsFixed(1)}ms under new constraints. Auto-reverted to ${_activeCheckpoint!.id}.';

      _latestVerdict = reason;

      _auditHistory.insert(
        0,
        EvaluationAuditReport(
          id: 'AUD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          timestamp: DateTime.now(),
          status: EvaluationStatus.rolledBack,
          preP0LatencyMs: pre.p0LatencyMs,
          postP0LatencyMs: post.p0LatencyMs,
          preQueuePressure: pre.queuePressurePercentage,
          postQueuePressure: post.queuePressurePercentage,
          verdictDetails: reason,
          didRollback: true,
        ),
      );

      _activeCheckpoint = null;
      return true; // Indicates a rollback was executed
    } else {
      // OPTIMAL: Optimizer's constraints improved or stabilized the pipeline!
      _status = EvaluationStatus.approved;
      final improvementDetails = 'OPTIMAL APPROVED: System stabilized. P0 Latency ${post.p0LatencyMs.toStringAsFixed(1)}ms (SLA preserved), Queue Pressure ${post.queuePressurePercentage.toStringAsFixed(1)}%.';
      _latestVerdict = improvementDetails;

      _auditHistory.insert(
        0,
        EvaluationAuditReport(
          id: 'AUD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          timestamp: DateTime.now(),
          status: EvaluationStatus.approved,
          preP0LatencyMs: pre.p0LatencyMs,
          postP0LatencyMs: post.p0LatencyMs,
          preQueuePressure: pre.queuePressurePercentage,
          postQueuePressure: post.queuePressurePercentage,
          verdictDetails: improvementDetails,
          didRollback: false,
        ),
      );

      _activeCheckpoint = null;
      return false;
    }
  }

  /// Manual revert back to original state.
  void forceRollback(PipelineRuntime runtime) {
    if (_activeCheckpoint != null) {
      runtime.setPolicy(_activeCheckpoint!.policy);
      _status = EvaluationStatus.rolledBack;
      _latestVerdict = 'MANUAL REVERT: User executed immediate rollback to checkpoint #${_activeCheckpoint!.id}.';
      _activeCheckpoint = null;
    }
  }
}
