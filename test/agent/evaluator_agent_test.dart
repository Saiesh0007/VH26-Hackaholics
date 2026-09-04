import 'package:flutter_test/flutter_test.dart';
import 'package:pulseflow/core/constraints/classification_constraints.dart';
import 'package:pulseflow/models/event.dart';
import 'package:pulseflow/models/pipeline_metrics.dart';
import 'package:pulseflow/simulation/pipeline_runtime.dart';
import 'package:pulseflow/agent/evaluator_agent.dart';

void main() {
  group('ClassificationConstraints Tests', () {
    test('Payment and financial events must classify into P0 Payment', () {
      final priority = ClassificationConstraints.classify(
        eventType: 'payment.webhook.charge',
        transactionValue: 120.0,
      );
      expect(priority, equals(WorkloadPriority.p0Payment));
    });

    test('Order events must classify into P0 Order', () {
      final priority = ClassificationConstraints.classify(
        eventType: 'order.placed',
      );
      expect(priority, equals(WorkloadPriority.p0Order));
    });

    test('Inventory events must classify into P1 Inventory', () {
      final priority = ClassificationConstraints.classify(
        eventType: 'inventory.stock_sync',
      );
      expect(priority, equals(WorkloadPriority.p1Inventory));
    });

    test('User activity events must classify into P2 Activity', () {
      final priority = ClassificationConstraints.classify(
        eventType: 'user.clickstream.browse',
      );
      expect(priority, equals(WorkloadPriority.p2Activity));
    });

    test('Telemetry & logs must classify into P3 Log', () {
      final priority = ClassificationConstraints.classify(
        eventType: 'system.debug_trace',
      );
      expect(priority, equals(WorkloadPriority.p3Log));
    });
  });

  group('EvaluatorAgent Tests', () {
    late EvaluatorAgent evaluator;
    late PipelineRuntime runtime;

    setUp(() {
      evaluator = EvaluatorAgent();
      runtime = PipelineRuntime();
    });

    test('Evaluator approves optimal performance when P0 SLA is preserved', () {
      final initialPolicy = runtime.activePolicy;
      final baselineMetrics = PipelineMetrics(
        eventRatePerMin: 1000,
        throughputPerSec: 15,
        systemLoadPercentage: 15,
        queuePressurePercentage: 10,
        p0LatencyMs: 25.0,
        p1LatencyMs: 35.0,
        p2LatencyMs: 50.0,
        p3LatencyMs: 75.0,
        criticalEventsLost: 0,
        totalDeferredCount: 0,
        totalShedCount: 0,
        workerUtilization: 30.0,
        timestamp: DateTime.now(),
      );

      evaluator.captureCheckpoint(
        policy: initialPolicy,
        metrics: baselineMetrics,
        reason: 'Optimizer tuning for moderate spike',
      );

      // Simulate healthy post-change metrics after observation window
      final optimalMetrics = baselineMetrics.copyWith(
        p0LatencyMs: 28.0, // Within healthy SLA
        queuePressurePercentage: 12,
      );

      // Tick 1
      evaluator.evaluateAndAudit(runtime, optimalMetrics);
      // Tick 2 (window met)
      final didRollback = evaluator.evaluateAndAudit(runtime, optimalMetrics);

      expect(didRollback, isFalse);
      expect(evaluator.status, equals(EvaluationStatus.approved));
      expect(evaluator.latestVerdict, contains('OPTIMAL APPROVED'));
    });

    test('Evaluator AUTONOMOUSLY REVERTS if proposed policy degrades P0 latency beyond SLA ceiling', () {
      final initialPolicy = runtime.activePolicy;
      final baselineMetrics = PipelineMetrics(
        eventRatePerMin: 1000,
        throughputPerSec: 15,
        systemLoadPercentage: 15,
        queuePressurePercentage: 10,
        p0LatencyMs: 25.0,
        p1LatencyMs: 35.0,
        p2LatencyMs: 50.0,
        p3LatencyMs: 75.0,
        criticalEventsLost: 0,
        totalDeferredCount: 0,
        totalShedCount: 0,
        workerUtilization: 30.0,
        timestamp: DateTime.now(),
      );

      evaluator.captureCheckpoint(
        policy: initialPolicy,
        metrics: baselineMetrics,
        reason: 'Optimizer test policy',
      );

      // Simulate a degrading post-change condition
      final degradedMetrics = baselineMetrics.copyWith(
        p0LatencyMs: 95.0, // Critical SLA ceiling (>75ms) breached!
        queuePressurePercentage: 65,
      );

      // Tick 1
      evaluator.evaluateAndAudit(runtime, degradedMetrics);
      // Tick 2 (window met -> triggers rollback)
      final didRollback = evaluator.evaluateAndAudit(runtime, degradedMetrics);

      expect(didRollback, isTrue);
      expect(evaluator.status, equals(EvaluationStatus.rolledBack));
      expect(evaluator.latestVerdict, contains('CRITICAL REVERT'));
    });
  });
}
