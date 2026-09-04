from typing import List
from pydantic import BaseModel
from models.domain_policy import DomainPolicy

class ValidationReport(BaseModel):
    isValid: bool
    errors: List[str]
    warnings: List[str]

class PolicyValidator:
    """
    Deterministic Safety & Business Rules Validator for Domain Policies.
    Ensures zero hallucination or unsafe configurations are ever activated.
    """
    @staticmethod
    def validate(policy: DomainPolicy) -> ValidationReport:
        errors: List[str] = []
        warnings: List[str] = []

        if not policy.domainName or len(policy.domainName.strip()) == 0:
            errors.append("RULE [DOM-01]: Domain name cannot be empty.")

        if not policy.eventTypes or len(policy.eventTypes) == 0:
            errors.append("RULE [DOM-02]: Domain policy must contain at least one event type.")
            return ValidationReport(isValid=False, errors=errors, warnings=warnings)

        p0_count = 0
        non_critical_count = 0

        for event in policy.eventTypes:
            # Rule 1: Priority code validity
            if event.priority not in ["P0", "P1", "P2", "P3"]:
                errors.append(f"RULE [PRI-01]: Event '{event.type}' has invalid priority '{event.priority}'. Must be P0, P1, P2, or P3.")

            if event.priority == "P0":
                p0_count += 1
            else:
                non_critical_count += 1

            # Rule 2: Critical event shedding prohibition
            if event.critical and event.canShed:
                errors.append(
                    f"RULE [SAF-01]: Critical event '{event.type}' violates safety invariants: 'critical=true' MUST imply 'canShed=false'."
                )

            # Rule 3: Critical event deferral prohibition
            if event.critical and event.canDefer:
                errors.append(
                    f"RULE [SAF-02]: Critical event '{event.type}' cannot be deferred: 'critical=true' MUST imply 'canDefer=false'."
                )

            # Rule 4: P0 low SLA cannot be batch-only
            if event.priority == "P0" and event.slaMs < 500 and event.preferredStrategy == "batch":
                errors.append(
                    f"RULE [SLA-01]: P0 event '{event.type}' has SLA of {event.slaMs}ms (<500ms). It cannot be configured for batch processing; immediate streaming is required."
                )

            # Rule 5: Critical + Retryable requires Idempotency
            if event.critical and event.retryable and not event.idempotencyRequired:
                errors.append(
                    f"RULE [REL-01]: Critical event '{event.type}' is retryable but lacks idempotency protection. 'idempotencyRequired' must be true to prevent duplicate side effects."
                )

            # Rule 6: Shedding requires explicit positive threshold
            if event.canShed and event.sheddingThreshold <= 0.0:
                errors.append(
                    f"RULE [SHD-01]: Non-critical event '{event.type}' has shedding enabled but sheddingThreshold is {event.sheddingThreshold}. Must be > 0.0 (e.g. 0.70)."
                )

            # Rule 7: Batch size ceiling
            if event.batchable and event.maxBatchSize > policy.globalSettings.maxBatchSizeLimit:
                errors.append(
                    f"RULE [BAT-01]: Event '{event.type}' maxBatchSize {event.maxBatchSize} exceeds safety limit of {policy.globalSettings.maxBatchSizeLimit}."
                )

            # Rule 8: Valid preferred strategy
            if event.preferredStrategy not in ["stream", "batch", "defer", "shed"]:
                errors.append(
                    f"RULE [STR-01]: Event '{event.type}' has invalid strategy '{event.preferredStrategy}'."
                )

        # Invariant: At least one P0 critical event for SLA guarantee
        if p0_count == 0:
            errors.append("RULE [DOM-03]: Domain must contain at least one P0 Critical event to establish the SLA protection lane.")

        # Warning if no non-critical events are present for adaptive shedding
        if non_critical_count == 0:
            warnings.append("WARNING: All events are critical P0. Adaptive shedding during extreme traffic surges will be constrained.")

        return ValidationReport(
            isValid=len(errors) == 0,
            errors=errors,
            warnings=warnings
        )
