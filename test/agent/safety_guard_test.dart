import 'package:flutter_test/flutter_test.dart';
import 'package:pulseflow/agent/safety_guard.dart';
import 'package:pulseflow/models/event.dart';
import 'package:pulseflow/models/pipeline_policy.dart';

void main() {
  group('SafetyGuard Tests', () {
    late SafetyGuard safetyGuard;

    setUp(() {
      safetyGuard = SafetyGuard();
    });

    test('Default policy should pass SafetyGuard validation', () {
      final policy = PipelinePolicy.defaultPolicy();
      final result = safetyGuard.validatePolicy(policy);
      expect(result.isApproved, isTrue);
    });

    test('P0 PAYMENT shedding proposal MUST BE REJECTED by SafetyGuard', () {
      final defaultPolicy = PipelinePolicy.defaultPolicy();
      final invalidPolicies = Map<WorkloadPriority, PriorityPolicy>.from(defaultPolicy.policies);

      invalidPolicies[WorkloadPriority.p0Payment] = invalidPolicies[WorkloadPriority.p0Payment]!.copyWith(
        mode: ProcessingStrategy.shed,
      );

      final testPolicy = PipelinePolicy(
        policies: invalidPolicies,
        timestamp: DateTime.now(),
        version: 'v-test-invalid',
        reason: 'Attempted to shed P0 Payment',
      );

      final result = safetyGuard.validatePolicy(testPolicy);
      expect(result.isApproved, isFalse);
      expect(result.explanation, contains('REJECTED by SafetyGuard'));
      expect(result.violatedPriority, equals(WorkloadPriority.p0Payment));
    });

    test('P0 ORDER shedding proposal MUST BE REJECTED by SafetyGuard', () {
      final defaultPolicy = PipelinePolicy.defaultPolicy();
      final invalidPolicies = Map<WorkloadPriority, PriorityPolicy>.from(defaultPolicy.policies);

      invalidPolicies[WorkloadPriority.p0Order] = invalidPolicies[WorkloadPriority.p0Order]!.copyWith(
        mode: ProcessingStrategy.shed,
      );

      final testPolicy = PipelinePolicy(
        policies: invalidPolicies,
        timestamp: DateTime.now(),
        version: 'v-test-invalid-order',
        reason: 'Attempted to shed P0 Order',
      );

      final result = safetyGuard.validatePolicy(testPolicy);
      expect(result.isApproved, isFalse);
      expect(result.violatedPriority, equals(WorkloadPriority.p0Order));
    });

    test('P3 LOG shedding IS ALLOWED under SafetyGuard rules', () {
      final defaultPolicy = PipelinePolicy.defaultPolicy();
      final validPolicies = Map<WorkloadPriority, PriorityPolicy>.from(defaultPolicy.policies);

      validPolicies[WorkloadPriority.p3Log] = validPolicies[WorkloadPriority.p3Log]!.copyWith(
        mode: ProcessingStrategy.shed,
        samplingRate: 0.20,
      );

      final testPolicy = PipelinePolicy(
        policies: validPolicies,
        timestamp: DateTime.now(),
        version: 'v-test-p3-shed',
        reason: 'Sampling P3 logs under extreme pressure',
      );

      final result = safetyGuard.validatePolicy(testPolicy);
      expect(result.isApproved, isTrue);
    });
  });
}
