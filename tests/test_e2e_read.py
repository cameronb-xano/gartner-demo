"""Cross-workspace READ fan-out tests.

Demonstrates that workspaces can pull data from each other (not just push).
The headline endpoint is GET /claims/{id}/360 which fans out reads to
Customer Profiling, Billing & Payments, and Notifications & Communications,
returning a single unified response.
"""
import time

import pytest

from conftest import GartnerClient, unique

pytestmark = [pytest.mark.e2e, pytest.mark.slow]


def test_claim_360_returns_unified_view(authed_client: GartnerClient, fresh_customer: dict):
    """Open a claim, run it through approve, then GET /360 — must include data
    from Tickets (claim, timeline) AND remote workspaces (profile, invoices, notifications)."""
    cid = fresh_customer["id"]
    claim = authed_client.create_claim(
        customer_id=cid, claim_type="auto", amount_requested=2750.0,
        summary="360 endpoint test", priority="high",
    ).assert_ok().body

    authed_client.update_claim(
        claim["id"], status="approved", amount_approved=2500.0, note="Approved by 360 test",
    ).assert_ok()

    time.sleep(0.6)

    resp = authed_client.claim_360(claim["id"])
    resp.assert_ok()
    body = resp.body

    assert body["claim"]["id"] == claim["id"]
    assert body["claim"]["claim_number"] == claim["claim_number"]
    assert "timeline" in body and len(body["timeline"]) >= 2

    assert body["profiling"]["_source"] == "gartner-profiling"
    assert body["profiling"]["data"] is not None, "profiling fan-out returned null"
    assert body["profiling"]["data"]["customer"]["id"] == cid

    assert body["billing"]["_source"] == "gartner-billing"
    invoices = body["billing"]["invoices"]
    assert any(inv["claim_ref"] == claim["claim_number"] for inv in invoices), \
        f"no matching invoice for {claim['claim_number']} in {invoices}"

    assert body["notifications"]["_source"] == "gartner-notify"
    sent = body["notifications"]["sent"]
    sent_templates = {n["template_name"] for n in sent}
    assert "claim_opened" in sent_templates
    assert "claim_approved" in sent_templates


def test_claim_360_works_when_remote_data_empty(authed_client: GartnerClient, fresh_customer: dict):
    """GET /360 right after opening — billing should be empty (no approval yet) but call still succeeds."""
    cid = fresh_customer["id"]
    claim = authed_client.create_claim(
        customer_id=cid, claim_type="travel", amount_requested=300.0,
        summary="360 empty-state test",
    ).assert_ok().body

    time.sleep(0.4)

    resp = authed_client.claim_360(claim["id"])
    resp.assert_ok()
    assert resp.body["billing"]["invoices"] == []
    assert resp.body["claim"]["status"] == "new"


def test_claim_360_missing_returns_error(authed_client: GartnerClient):
    resp = authed_client.claim_360(999_999_999)
    assert resp.status in (400, 404)


def test_customer_insights_aggregates_remote_data(authed_client: GartnerClient, fresh_customer: dict):
    """GET /customers/{id}/insights should pull profile from Profiling AND notifications from Notify."""
    cid = fresh_customer["id"]
    authed_client.create_claim(
        customer_id=cid, claim_type="auto", amount_requested=1200.0,
        summary="insights test claim",
    ).assert_ok()

    time.sleep(0.5)

    resp = authed_client.customer_insights(cid)
    resp.assert_ok()
    body = resp.body

    assert body["customer"]["id"] == cid

    assert body["profile"]["_source"] == "gartner-profiling"
    assert body["profile"]["data"] is not None
    assert body["profile"]["data"]["customer"]["id"] == cid
    assert body["profile"]["data"]["customer"]["risk_score"] >= 5  # claim_opened bumps it

    assert body["recent_notifications"]["_source"] == "gartner-notify"
    assert len(body["recent_notifications"]["items"]) >= 1

    assert body["open_claims"]["_source"] == "local"
    assert len(body["open_claims"]["items"]) >= 1


def test_customer_insights_missing_returns_error(authed_client: GartnerClient):
    resp = authed_client.customer_insights(999_999_999)
    assert resp.status in (400, 404)
