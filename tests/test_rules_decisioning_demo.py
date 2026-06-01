"""Focused tests for the Rules & Decisioning demo change."""

import os

import requests

from conftest import BASE, GartnerClient


RULES_URL = f"{BASE}/api:gartner-rules-decisioning"
POLICY_URL = f"{BASE}/api:gartner-policy-data"


def test_snowflake_claim_99_has_weather_context():
    """The recording claim should expose weather-related facts from Snowflake."""
    policy = requests.get(f"{POLICY_URL}/customer-data/99", timeout=20).json()

    assert policy["source"] == "snowflake"
    assert policy["policy_number"] == "POL-PROP-0099"
    assert "storm" in policy["summary"].lower() or "roof" in policy["summary"].lower()


def test_rules_decisioning_demo_expected_route():
    """Supports both reset baseline and post-change catastrophe assertions."""
    expect_catastrophe = os.environ.get("EXPECT_CATASTROPHE_RULE") == "1"
    policy = requests.get(f"{POLICY_URL}/customer-data/99", timeout=20).json()
    history = requests.get(f"{POLICY_URL}/claim-history/104", timeout=20).json()

    decision = requests.post(
        f"{RULES_URL}/decisions/evaluate",
        json={
            "claim_id": 99,
            "claim_type": "property",
            "amount_requested": 5000,
            "policy_status": policy["policy_status"],
            "policy_age_months": policy["policy_age_months"],
            "fraud_flag": history["fraud_flag"],
            "summary": policy["summary"],
            "coverage_tier": policy["coverage_tier"],
        },
        timeout=20,
    ).json()

    if expect_catastrophe:
        assert decision["assigned_queue"] == "catastrophe_review"
        assert decision["priority"] == "urgent"
        assert "catastrophe" in decision["reason"].lower()
    else:
        assert decision["assigned_queue"] == "property_specialist"
        assert decision["priority"] == "high"


def test_customer_claims_360_uses_rules_decisioning(authed_client: GartnerClient):
    """Customer Claims should pass Snowflake facts into Rules & Decisioning."""
    expect_catastrophe = os.environ.get("EXPECT_CATASTROPHE_RULE") == "1"

    view = authed_client.claim_360(99).assert_ok().body
    decision = view["rules_decisioning"]["decision"]

    assert view["policy_data"]["customer_data"]["source"] == "snowflake"
    assert decision["decision"] == "escalate"
    assert decision["assigned_queue"] == (
        "catastrophe_review" if expect_catastrophe else "property_specialist"
    )


def test_demo_claim_reset_state(authed_client: GartnerClient):
    """After reset, the visible claim should be clean before the button click."""
    if os.environ.get("EXPECT_CATASTROPHE_RULE") == "1":
        return

    view = authed_client.claim_360(99).assert_ok().body
    claim = view["claim"]

    assert claim["status"] == "new"
    assert claim["priority"] == "high"
    assert claim.get("assigned_queue") in (None, "unassigned")
    assert claim.get("amount_approved") in (None, 0)
    assert len(view["timeline"]) <= 1
