import 'package:flutter_test/flutter_test.dart';
import 'package:pulseflow/models/domain_policy.dart';
import 'package:pulseflow/models/event.dart';
import 'package:pulseflow/models/pipeline_policy.dart';
import 'package:pulseflow/core/constraints/policy_validator.dart';
import 'package:pulseflow/simulation/pipeline_runtime.dart';
import 'package:pulseflow/services/ai_domain_service.dart';

void main() {
  group('Phase 2 & 4: Domain Policy Schema & Strict Validation', () {
    test('Predefined E-Commerce policy is valid', () {
      final policy = DomainPolicy.ecommerce();
      final result = DartPolicyValidator.validate(policy);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(policy.eventTypes.length, greaterThanOrEqualTo(5));
    });

    test('Predefined Hospital Disaster policy is valid and has critical events', () {
      final policy = DomainPolicy.hospital();
      final result = DartPolicyValidator.validate(policy);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(policy.eventTypes.any((e) => e.isCritical), isTrue);
    });

    test('Predefined Education policy is valid', () {
      final policy = DomainPolicy.education();
      final result = DartPolicyValidator.validate(policy);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('REJECTS policy when critical event has canShed = true', () {
      const invalidEvent = EventPolicy(
        name: 'Emergency Ambulance',
        priority: 'P0',
        isCritical: true,
        slaMs: 100,
        preferredStrategy: 'stream',
        isBatchable: false,
        maxBatchSize: 1,
        canDefer: false,
        canShed: true, // VIOLATION!
        sheddingThreshold: 0.5,
        isRetryable: true,
        idempotencyRequired: true,
        processingCost: 1.0,
        dependencies: [],
      );

      final policy = DomainPolicy(
        domainName: 'Invalid Hospital',
        description: 'Test invalid policy',
        eventTypes: [invalidEvent],
      );

      final result = DartPolicyValidator.validate(policy);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('CANNOT be sheddable')), isTrue);
    });

    test('REJECTS policy when critical retryable event lacks idempotency', () {
      const invalidEvent = EventPolicy(
        name: 'Payment Capture',
        priority: 'P0',
        isCritical: true,
        slaMs: 150,
        preferredStrategy: 'stream',
        isBatchable: false,
        maxBatchSize: 1,
        canDefer: false,
        canShed: false,
        sheddingThreshold: 0.0,
        isRetryable: true,
        idempotencyRequired: false, // VIOLATION!
        processingCost: 1.0,
        dependencies: [],
      );

      final policy = DomainPolicy(
        domainName: 'Invalid Payments',
        description: 'Test invalid idempotency',
        eventTypes: [invalidEvent],
      );

      final result = DartPolicyValidator.validate(policy);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('idempotency protection')), isTrue);
    });

    test('REJECTS P0 event with sub-500ms SLA configured as batch-only', () {
      const invalidEvent = EventPolicy(
        name: 'Emergency Code Red',
        priority: 'P0',
        isCritical: true,
        slaMs: 100,
        preferredStrategy: 'batch', // VIOLATION for P0 < 500ms
        isBatchable: true,
        maxBatchSize: 50,
        canDefer: false,
        canShed: false,
        sheddingThreshold: 0.0,
        isRetryable: true,
        idempotencyRequired: true,
        processingCost: 1.0,
        dependencies: [],
      );

      final policy = DomainPolicy(
        domainName: 'Invalid Code Red',
        description: 'Test invalid batch strategy for P0',
        eventTypes: [invalidEvent],
      );

      final result = DartPolicyValidator.validate(policy);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('cannot have preferredStrategy="batch"')), isTrue);
    });
  });

  group('Phase 6 & 7: AdaptQ Runtime Engine & Domain Policy Integration', () {
    test('DomainPolicy converts to operational PipelinePolicy', () {
      final domainPolicy = DomainPolicy.hospital();
      final pipelinePolicy = domainPolicy.toPipelinePolicy();

      expect(pipelinePolicy.policies[WorkloadPriority.p0Payment], isNotNull);
      expect(pipelinePolicy.policies[WorkloadPriority.p0Payment]!.mode, ProcessingStrategy.stream);
      expect(pipelinePolicy.policies[WorkloadPriority.p3Log]!.samplingRate, lessThan(1.0));
    });

    test('PipelineRuntime loads and switches domain policy dynamically', () {
      final runtime = PipelineRuntime();
      expect(runtime.activeDomainPolicy.domainName, 'E-Commerce Flash Sale');

      // Switch to Hospital
      runtime.setDomainPolicy(DomainPolicy.hospital());
      expect(runtime.activeDomainPolicy.domainName, 'Hospital Disaster Management');

      // Tick simulation under hospital policy
      final metrics = runtime.tickSimulation();
      expect(metrics.criticalEventsLost, 0); // 0 Critical loss guarantee
    });

    test('Critical event guarantee holds during simulated load surge', () {
      final runtime = PipelineRuntime();
      runtime.setDomainPolicy(DomainPolicy.hospital());
      runtime.setTrafficRate(20000); // 20x Spike

      for (int i = 0; i < 5; i++) {
        final metrics = runtime.tickSimulation();
        expect(metrics.criticalEventsLost, 0); // Must NEVER drop critical events
      }
    });

    test('Idempotent duplicate event injection is handled without dropping', () {
      final runtime = PipelineRuntime();
      runtime.setDomainPolicy(DomainPolicy.ecommerce());
      runtime.injectDuplicateEvent();

      final first = runtime.recentEvents.first;
      expect(first.id, contains('DUP-IDEMPOTENT'));
      expect(first.decisionReason, contains('IDEMPOTENCY SAFEGUARD'));
    });

    test('Worker failure chaos reduces capacity without critical event breach', () {
      final runtime = PipelineRuntime();
      runtime.setDomainPolicy(DomainPolicy.hospital());
      runtime.killWorker();

      final metrics = runtime.tickSimulation();
      expect(metrics.criticalEventsLost, 0);
    });
  });

  group('Phase 18: Offline / Failure Fallback Resiliency', () {
    test('AiDomainService returns deterministic fallback policy when offline', () async {
      // Points to unreachable port
      final service = AiDomainService(baseUrl: 'http://localhost:9999/api/v1');
      final policy = await service.generatePolicy(
        'Hospital emergency disaster with patient triage and ambulance telemetry',
      );

      expect(policy, isNotNull);
      expect(policy.domainName, 'Hospital Disaster Management');
      expect(policy.eventTypes.length, greaterThanOrEqualTo(5));

      final validation = DartPolicyValidator.validate(policy);
      expect(validation.isValid, isTrue);
    });

    test('AiDomainService fallback Copilot provides structured sections', () async {
      final service = AiDomainService(baseUrl: 'http://localhost:9999/api/v1');
      final res = await service.askCopilot(
        prompt: 'Why are clicks being batched?',
        policy: DomainPolicy.ecommerce(),
        metrics: {'events_per_minute': 20000, 'queue_depth': 4500, 'worker_utilization': 0.85},
      );

      expect(res.containsKey('facts'), isTrue);
      expect(res.containsKey('current_metrics'), isTrue);
      expect(res.containsKey('policy'), isTrue);
      expect(res.containsKey('recommendation'), isTrue);
    });

    test('Deterministic What-If simulator provides numerical predictions', () async {
      final service = AiDomainService(baseUrl: 'http://localhost:9999/api/v1');
      final res = await service.simulateWhatIf(
        policy: DomainPolicy.ecommerce(),
        trafficRate: 50000,
        workers: 4,
      );

      expect(res.containsKey('predicted'), isTrue);
      final pred = res['predicted'] as Map<String, dynamic>;
      expect(pred['critical_dropped'], 0);
      expect(pred['p0_latency_ms'], lessThanOrEqualTo(250.0));
      expect(pred['estimated_cost_per_hour'], greaterThan(0));
    });
  });
}
