import '../models/event.dart';
import '../models/pipeline_policy.dart';
import '../core/constants/app_constants.dart';

class SafetyValidationResult {
  final bool isApproved;
  final String explanation;
  final WorkloadPriority? violatedPriority;

  const SafetyValidationResult({
    required this.isApproved,
    required this.explanation,
    this.violatedPriority,
  });

  factory SafetyValidationResult.approved() {
    return const SafetyValidationResult(
      isApproved: true,
      explanation: 'Action complies with all immutable safety rules.',
    );
  }

  factory SafetyValidationResult.rejected(String reason, [WorkloadPriority? priority]) {
    return SafetyValidationResult(
      isApproved: false,
      explanation: reason,
      violatedPriority: priority,
    );
  }
}

class SafetyGuard {
  /// Validates a candidate PipelinePolicy before execution.
  SafetyValidationResult validatePolicy(PipelinePolicy policy) {
    for (final entry in policy.policies.entries) {
      final priority = entry.key;
      final pPolicy = entry.value;

      // Rule 1: P0 Payment & Order MUST NEVER be shed
      if (priority.isCritical) {
        if (pPolicy.mode == ProcessingStrategy.shed) {
          return SafetyValidationResult.rejected(
            'REJECTED by SafetyGuard: Critical workloads (${priority.displayName}) are protected by immutable safety policy and cannot be shed.',
            priority,
          );
        }

        if (pPolicy.samplingRate < 1.0) {
          return SafetyValidationResult.rejected(
            'REJECTED by SafetyGuard: Critical workloads (${priority.displayName}) require 100% sampling rate (sampling disabled).',
            priority,
          );
        }
      }

      // Rule 2: Maximum batch size check
      if (pPolicy.batchSize > AppConstants.maxBatchSizeLimit) {
        return SafetyValidationResult.rejected(
          'REJECTED by SafetyGuard: Batch size ${pPolicy.batchSize} exceeds maximum safety ceiling of ${AppConstants.maxBatchSizeLimit}.',
          priority,
        );
      }

      // Rule 3: Maximum deferral window check
      if (pPolicy.deferWindowSeconds > AppConstants.maxDeferWindowSecondsLimit) {
        return SafetyValidationResult.rejected(
          'REJECTED by SafetyGuard: Defer window ${pPolicy.deferWindowSeconds}s exceeds maximum safety limit of ${AppConstants.maxDeferWindowSecondsLimit}s.',
          priority,
        );
      }

      // Rule 4: Maximum shedding/sampling check (for non-critical)
      if (pPolicy.samplingRate < (1.0 - AppConstants.maxSamplingRateLimit)) {
        return SafetyValidationResult.rejected(
          'REJECTED by SafetyGuard: Shedding rate exceeds safe threshold (max 90% shed allowed).',
          priority,
        );
      }
    }

    return SafetyValidationResult.approved();
  }
}
