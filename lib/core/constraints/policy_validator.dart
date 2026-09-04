import '../../models/domain_policy.dart';

class PolicyValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const PolicyValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
}

class DartPolicyValidator {
  static PolicyValidationResult validate(DomainPolicy policy) {
    final errors = <String>[];
    final warnings = <String>[];

    if (policy.domainName.trim().isEmpty) {
      errors.add('domainName cannot be empty.');
    }

    if (policy.eventTypes.isEmpty) {
      errors.add('Policy must specify at least one event type.');
    }

    final validPriorities = {'P0', 'P1', 'P2', 'P3'};
    final eventNames = <String>{};
    var hasCritical = false;

    for (final event in policy.eventTypes) {
      if (event.name.trim().isEmpty) {
        errors.add('Event type name cannot be empty.');
      }
      if (eventNames.contains(event.name.toLowerCase())) {
        errors.add('Duplicate event type name: "${event.name}".');
      }
      eventNames.add(event.name.toLowerCase());

      if (!validPriorities.contains(event.priority)) {
        errors.add('Event "${event.name}" has invalid priority "${event.priority}". Allowed: P0, P1, P2, P3.');
      }

      if (event.isCritical) {
        hasCritical = true;
        // RULE: critical MUST imply canShed = false
        if (event.canShed) {
          errors.add('RULE VIOLATION: Critical event "${event.name}" CANNOT be sheddable (canShed must be false).');
        }
        // RULE: critical MUST imply canDefer = false
        if (event.canDefer) {
          errors.add('RULE VIOLATION: Critical event "${event.name}" CANNOT be deferrable (canDefer must be false).');
        }
        // RULE: critical events MUST have idempotency protection if retryable
        if (event.isRetryable && !event.idempotencyRequired) {
          errors.add('RULE VIOLATION: Critical retryable event "${event.name}" MUST have idempotency protection enabled.');
        }
      }

      // RULE: P0 should not be batch-only if SLA is very tight
      if (event.priority == 'P0' && event.slaMs < 500 && event.preferredStrategy == 'batch') {
        errors.add('RULE VIOLATION: Event "${event.name}" is P0 with SLA < 500ms and cannot have preferredStrategy="batch".');
      }

      // RULE: Shedding enabled MUST have an explicit threshold
      if (event.canShed && event.sheddingThreshold <= 0.0) {
        errors.add('RULE VIOLATION: Event "${event.name}" allows shedding but has sheddingThreshold <= 0.');
      }

      // RULE: Batchable ceiling
      if (event.isBatchable && event.maxBatchSize <= 1) {
        warnings.add('Event "${event.name}" is batchable but maxBatchSize <= 1.');
      }

      if (event.slaMs <= 0) {
        errors.add('Event "${event.name}" has invalid slaMs (${event.slaMs}). Must be > 0.');
      }
    }

    if (!hasCritical) {
      warnings.add('Warning: Policy does not define any critical (P0/Critical) event types.');
    }

    return PolicyValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
}
