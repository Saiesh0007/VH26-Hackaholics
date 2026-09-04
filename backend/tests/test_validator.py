import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from models.domain_policy import DomainPolicy, EventPolicy, GlobalPolicySettings
from models.predefined_domains import get_ecommerce_policy, get_hospital_policy, get_education_policy
from validator.policy_validator import PolicyValidator

def test_predefined_policies_are_valid():
    for name, pol in [("ecom", get_ecommerce_policy()), ("hosp", get_hospital_policy()), ("edu", get_education_policy())]:
        report = PolicyValidator.validate(pol)
        assert report.isValid, f"{name} failed validation: {report.errors}"
    print("Predefined policies all valid!")

def test_critical_shedding_rejected():
    policy = get_ecommerce_policy()
    # Violate Rule 1: Critical shed
    policy.eventTypes[0].canShed = True
    report = PolicyValidator.validate(policy)
    assert not report.isValid, "Should reject critical event with canShed=True"
    assert any("SAF-01" in err for err in report.errors)
    print("Rule SAF-01 critical shedding rejection verified!")

def test_critical_deferral_rejected():
    policy = get_ecommerce_policy()
    # Violate Rule 2: Critical defer
    policy.eventTypes[0].canDefer = True
    report = PolicyValidator.validate(policy)
    assert not report.isValid, "Should reject critical event with canDefer=True"
    assert any("SAF-02" in err for err in report.errors)
    print("Rule SAF-02 critical deferral rejection verified!")

def test_p0_batch_only_rejected():
    policy = get_ecommerce_policy()
    # Violate Rule 3: P0 batch only with low SLA
    policy.eventTypes[0].slaMs = 100
    policy.eventTypes[0].preferredStrategy = "batch"
    report = PolicyValidator.validate(policy)
    assert not report.isValid
    assert any("SLA-01" in err for err in report.errors)
    print("Rule SLA-01 P0 batch rejection verified!")

if __name__ == "__main__":
    test_predefined_policies_are_valid()
    test_critical_shedding_rejected()
    test_critical_deferral_rejected()
    test_p0_batch_only_rejected()
    print("ALL BACKEND TESTS PASSED!")
