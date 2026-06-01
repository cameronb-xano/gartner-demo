"""End-to-end cross-workspace lifecycle tests.

These verify that a user action in Tickets & Claims correctly fans out to
Customer Profiling, Notifications, and Billing & Payments.
"""
import time

import pytest

from conftest import GartnerClient, unique

pytestmark = [pytest.mark.e2e, pytest.mark.slow]


def test_open_claim_fans_out_to_profiling_and_notify(authed_client: GartnerClient, fresh_customer: dict):
    """Opening a claim should record a behavior event AND send an email."""
    cid = fresh_customer["id"]
    customer_email = fresh_customer["email"]

    claim = authed_client.create_claim(
        customer_id=cid, claim_type="auto", amount_requested=2200.0,
        summary="E2E test claim", priority="medium",
    ).assert_ok().body

    time.sleep(0.5)  # let downstream calls settle

    profile = authed_client.profiling_get_customer(cid).assert_ok().body
    event_types = {e["event_type"] for e in profile["recent_events"]}
    assert "claim_opened" in event_types, f"profiling missing claim_opened, has {event_types}"

    notifications = authed_client.notify_list(customer_id=cid).assert_ok().body
    sent_templates = {n["template_name"] for n in notifications["items"]}
    assert "claim_opened" in sent_templates, f"notify missing claim_opened, has {sent_templates}"

    opened_email = next(
        (n for n in notifications["items"] if n["template_name"] == "claim_opened"),
        None,
    )
    assert opened_email is not None
    assert opened_email["recipient"] == customer_email
    assert claim["claim_number"] in opened_email["body"]


def test_approve_claim_fans_out_to_billing(authed_client: GartnerClient, fresh_customer: dict):
    """Approving a claim should create a payout invoice in Billing."""
    cid = fresh_customer["id"]
    claim = authed_client.create_claim(
        customer_id=cid, claim_type="property", amount_requested=5000.0,
        summary="E2E approve test", priority="high",
    ).assert_ok().body

    authed_client.update_claim(
        claim["id"], status="approved", amount_approved=4750.0, note="Approved by E2E suite",
    ).assert_ok()

    time.sleep(0.5)

    invoices = authed_client.billing_list_invoices(claim_ref=claim["claim_number"]).assert_ok().body
    assert invoices["itemsReceived"] >= 1, f"no invoice for {claim['claim_number']}"
    inv = invoices["items"][0]
    assert inv["amount"] == 4750.0
    assert inv["direction"] == "inbound"
    assert inv["status"] == "issued"


def test_full_claim_lifecycle(authed_client: GartnerClient, fresh_customer: dict):
    """new → in_review → approved → paid: every transition logs in Profiling and Notify."""
    cid = fresh_customer["id"]
    claim = authed_client.create_claim(
        customer_id=cid, claim_type="health", amount_requested=1800.0,
        summary="Full lifecycle E2E", priority="medium",
    ).assert_ok().body

    for status in ("in_review", "approved", "paid"):
        update_kwargs = {"status": status}
        if status == "approved":
            update_kwargs["amount_approved"] = 1700.0
        authed_client.update_claim(claim["id"], **update_kwargs).assert_ok()
        time.sleep(0.4)

    profile = authed_client.profiling_get_customer(cid).assert_ok().body
    event_types = [e["event_type"] for e in profile["recent_events"]]
    for expected in ("claim_opened", "claim_in_review", "claim_approved", "claim_paid"):
        assert expected in event_types, f"missing {expected} in {event_types}"

    notifications = authed_client.notify_list(customer_id=cid).assert_ok().body
    sent_templates = [n["template_name"] for n in notifications["items"]]
    for expected in ("claim_opened", "claim_in_review", "claim_approved", "claim_paid"):
        assert expected in sent_templates, f"missing {expected} email"

    invoices = authed_client.billing_list_invoices(claim_ref=claim["claim_number"]).assert_ok().body
    assert invoices["itemsReceived"] == 1, "should have exactly one payout invoice"


def test_denied_claim_does_not_create_invoice(authed_client: GartnerClient, fresh_customer: dict):
    """Denied claims should fan out to Profiling and Notify but NOT create a Billing invoice."""
    cid = fresh_customer["id"]
    claim = authed_client.create_claim(
        customer_id=cid, claim_type="liability", amount_requested=999.0,
        summary="Denied lifecycle E2E", priority="low",
    ).assert_ok().body

    authed_client.update_claim(
        claim["id"], status="denied", note="Denied per investigation",
    ).assert_ok()

    time.sleep(0.5)

    invoices = authed_client.billing_list_invoices(claim_ref=claim["claim_number"]).assert_ok().body
    assert invoices["itemsReceived"] == 0, "denied claims should not create invoices"

    notifications = authed_client.notify_list(customer_id=cid).assert_ok().body
    templates = {n["template_name"] for n in notifications["items"]}
    assert "claim_denied" in templates


def test_customer_create_mirrors_to_profiling(authed_client: GartnerClient):
    """Creating a customer in Tickets should mirror it into Customer Profiling."""
    email = unique("mirror") + "@test.com"
    authed_client.create_customer(
        first_name="Mirror", last_name="Test", email=email,
        policy_number=unique("POL").upper(),
    ).assert_ok()
    time.sleep(0.4)

    profiling = authed_client.profiling_list_customers(search=email).assert_ok().body
    matches = [c for c in profiling["items"] if c["email"] == email]
    assert len(matches) >= 1, f"customer not mirrored to profiling: {email}"


def test_downstream_outage_does_not_block_claim(authed_client: GartnerClient, fresh_customer: dict):
    """Even if Notify/Profiling are slow or down, claim creation should succeed.

    We can't actually take services down here, but we can verify the parent
    operation returns 2xx independent of downstream behavior. The fan-out
    helpers wrap each call in try_catch so failures are non-fatal.
    """
    resp = authed_client.create_claim(
        customer_id=fresh_customer["id"],
        claim_type="travel", amount_requested=500.0, summary="resilience test",
    )
    resp.assert_ok()
    assert resp.body["claim_number"].startswith("CLM-")
