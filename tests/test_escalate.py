"""Test for the POST /claims/{id}/escalate endpoint built live during the demo.

Skipped by default — only runs after the endpoint has been promoted from
sandbox to live during the demo.

Run with: ./run.sh test_escalate.py
"""
import time

import pytest

from conftest import GartnerClient

pytestmark = [pytest.mark.tickets, pytest.mark.slow]


def _endpoint_exists(client: GartnerClient) -> bool:
    """Probe whether /escalate has been promoted to live."""
    resp = client._call("POST", f"{client.session.adapters['https://'].__class__.__name__ and ''}", json={})
    # Use a known invalid claim id and check we get an auth/validation error, not 404 on the route
    probe = client.escalate_claim(0)
    return probe.status not in (404,) or "not found" not in str(probe.body).lower() or "auth" in str(probe.body).lower()


def test_escalate_bumps_priority_and_logs_event(authed_client: GartnerClient, fresh_customer: dict):
    """Open a low-priority claim then escalate it — priority becomes urgent, status becomes in_review,
    timeline gets the escalation event, customer gets a claim_escalated email."""
    cid = fresh_customer["id"]
    claim = authed_client.create_claim(
        customer_id=cid, claim_type="health", amount_requested=4500.0,
        summary="Initial submission, low priority", priority="low",
    ).assert_ok().body

    resp = authed_client.escalate_claim(claim["id"], reason="customer hospitalized")
    if resp.status == 404:
        pytest.skip("/escalate endpoint not yet promoted from sandbox to live")
    resp.assert_ok()
    assert resp.body["claim"]["priority"] == "urgent"
    assert resp.body["claim"]["status"] == "in_review"
    assert resp.body["claim"]["sla_due_at"] > resp.body["escalated_at"]

    timeline = authed_client.claim_timeline(claim["id"]).assert_ok().body
    messages = [e.get("message", "") for e in timeline["items"]]
    assert any("Escalated" in m for m in messages), f"escalation event not found in timeline: {messages}"

    time.sleep(0.5)
    notifications = authed_client.notify_list(customer_id=cid).assert_ok().body
    templates = [n["template_name"] for n in notifications["items"]]
    assert "claim_escalated" in templates, f"escalation email not sent, got {templates}"


def test_escalate_missing_claim_returns_error(authed_client: GartnerClient):
    resp = authed_client.escalate_claim(999_999_999, reason="test")
    if resp.status == 404 and "not yet" in str(resp.body).lower():
        pytest.skip("/escalate not promoted yet")
    assert resp.status in (400, 404)
