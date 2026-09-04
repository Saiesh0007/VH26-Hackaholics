import '../models/event.dart';
import '../models/pipeline_metrics.dart';
import '../models/pipeline_policy.dart';
import 'safety_guard.dart';
import 'evaluator_agent.dart';
import '../simulation/pipeline_runtime.dart';

enum OptimizerStatus {
  monitoring,
  analyzingLogs,
  adaptingConstraints,
  policyDeployed,
}

/// Optimizer Agent (Operational Constraint Tuner):
/// Analyzes real-time metrics and event logs. Dynamically tunes execution
/// constraints (micro-batching size, worker allocation, deferral windows,
/// and sampling ratios) to optimize system throughput and SLA protection.
class OptimizerAgent {
  final SafetyGuard safetyGuard = SafetyGuard();
  OptimizerStatus _status = OptimizerStatus.monitoring;
  String _activeConstraintRationale = 'Baseline streaming constraints active.';
  int _optimizationsCount = 0;

  OptimizerStatus get status => _status;
  String get activeConstraintRationale => _activeConstraintRationale;
  int get optimizationsCount => _optimizationsCount;

  /// Analyze telemetry and dynamically adapt system constraints.
  /// If a change is proposed, it records a checkpoint with the Evaluator Agent.
  PipelinePolicy? analyzeAndTuneConstraints({
    required PipelineRuntime runtime,
    required PipelineMetrics metrics,
    required EvaluatorAgent evaluator,
  }) {
    _status = OptimizerStatus.monitoring;
    final rate = metrics.eventRatePerMin;
    final currentPolicy = runtime.activePolicy;

    // Condition 1: Baseline Traffic -> Standard Streaming Constraints
    if (rate <= 2000 && currentPolicy.policies[WorkloadPriority.p3Log]!.mode != ProcessingStrategy.stream) {
      _status = OptimizerStatus.adaptingConstraints;
      final newPolicy = PipelinePolicy.defaultPolicy();
      _activeConstraintRationale = 'Restored baseline constraints: 1-by-1 streaming across all queues.';
      
      evaluator.captureCheckpoint(
        policy: currentPolicy,
        metrics: metrics,
        reason: 'Restoring baseline constraints after traffic normalization.',
      );

      _optimizationsCount++;
      return newPolicy;
    }

    // Condition 2: Moderate Traffic Spike (3k - 15k e/min) -> Tune Micro-Batch Constraints
    if (rate > 3000 && rate < 15000) {
      if (currentPolicy.policies[WorkloadPriority.p2Activity]!.mode == ProcessingStrategy.stream) {
        _status = OptimizerStatus.analyzingLogs;
        
        final updated = Map<WorkloadPriority, PriorityPolicy>.from(currentPolicy.policies);
        // Tune P2 Activity constraints
        updated[WorkloadPriority.p2Activity] = updated[WorkloadPriority.p2Activity]!.copyWith(
          mode: ProcessingStrategy.batch,
          batchSize: 250,
        );
        // Tune P3 Log constraints
        updated[WorkloadPriority.p3Log] = updated[WorkloadPriority.p3Log]!.copyWith(
          mode: ProcessingStrategy.batch,
          batchSize: 500,
        );

        final proposed = PipelinePolicy(
          policies: updated,
          timestamp: DateTime.now(),
          version: 'opt-v2.1-batch',
          reason: 'Telemetry Analysis: Queue buildup detected. Dynamic constraint: P2 Batch(250), P3 Batch(500).',
        );

        // Safety verification
        final check = safetyGuard.validatePolicy(proposed);
        if (check.isApproved) {
          evaluator.captureCheckpoint(
            policy: currentPolicy,
            metrics: metrics,
            reason: proposed.reason,
          );
          _status = OptimizerStatus.policyDeployed;
          _activeConstraintRationale = proposed.reason;
          _optimizationsCount++;
          return proposed;
        }
      }
    }

    // Condition 3: Critical Traffic Surge (15k+ e/min) -> Tune Deferral & Sampling Constraints
    if (rate >= 15000) {
      final p3Mode = currentPolicy.policies[WorkloadPriority.p3Log]!.mode;
      if (p3Mode != ProcessingStrategy.shed || metrics.queuePressurePercentage > 50) {
        _status = OptimizerStatus.analyzingLogs;

        final updated = Map<WorkloadPriority, PriorityPolicy>.from(currentPolicy.policies);

        // CONSTRAINT: P0 Payments & Orders MUST REMAIN 100% STREAMING (Invariant)
        updated[WorkloadPriority.p0Payment] = updated[WorkloadPriority.p0Payment]!.copyWith(
          mode: ProcessingStrategy.stream,
          workerCount: 12,
        );
        updated[WorkloadPriority.p0Order] = updated[WorkloadPriority.p0Order]!.copyWith(
          mode: ProcessingStrategy.stream,
          workerCount: 12,
        );

        // CONSTRAINT: P1 Inventory Micro-batching
        updated[WorkloadPriority.p1Inventory] = updated[WorkloadPriority.p1Inventory]!.copyWith(
          mode: ProcessingStrategy.batch,
          batchSize: 100,
        );

        // CONSTRAINT: P2 Activity Deferral (30-second window)
        updated[WorkloadPriority.p2Activity] = updated[WorkloadPriority.p2Activity]!.copyWith(
          mode: ProcessingStrategy.defer,
          deferWindowSeconds: 30,
        );

        // CONSTRAINT: P3 Log Sampling/Shedding (80% shed)
        updated[WorkloadPriority.p3Log] = updated[WorkloadPriority.p3Log]!.copyWith(
          mode: ProcessingStrategy.shed,
          samplingRate: 0.20,
        );

        final proposed = PipelinePolicy(
          policies: updated,
          timestamp: DateTime.now(),
          version: 'opt-v3.0-surge',
          reason: 'Surge Optimization: P0 Locked to Stream (12 workers), P1 Batch(100), P2 Defer(30s), P3 Sample(20%).',
        );

        // Safety verification
        final check = safetyGuard.validatePolicy(proposed);
        if (check.isApproved) {
          evaluator.captureCheckpoint(
            policy: currentPolicy,
            metrics: metrics,
            reason: proposed.reason,
          );
          _status = OptimizerStatus.policyDeployed;
          _activeConstraintRationale = proposed.reason;
          _optimizationsCount++;
          return proposed;
        }
      }
    }

    return null;
  }
}
