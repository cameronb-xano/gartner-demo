"""Tickets & Claims workspace (workspace 1) - claims, tickets, timeline."""
import pytest

from conftest import GartnerClient, unique

pytestmark = pytest.mark.tickets


def test_signup_returns_token(client: GartnerClient):
    email = unique("agent") + "@test.com"
    resp = client.signup(email=email, password="Test1234!", name="Test")
    resp.assert_ok()
    assert "token" in resp.body
    assert resp.body["user"]["email"] == email


def test_signup_then_login_works(client: GartnerClient):
    email = unique("agent") + "@test.com"
    client.signup(email=email, password="Test1234!").assert_ok()
    resp = client.login(email=email, password="Test1234!")
    resp.assert_ok()
    assert "token" in resp.body


def test_login_wrong_password_denied(client: GartnerClient):
    email = unique("agent") + "@test.com"
    client.signup(email=email, password="Test1234!").assert_ok()
    resp = client.login(email=email, password="Wrong!")
    resp.assert_status(403)


def test_me_requires_auth(client: GartnerClient):
    resp = client.me()
    assert resp.status in (401, 403)


def test_me_returns_authed_user(authed_client: GartnerClient):
    resp = authed_client.me()
    resp.assert_ok()
    assert "email" in resp.body


def test_create_customer(authed_client: GartnerClient):
    email = unique("cust") + "@test.com"
    resp = authed_client.create_customer(
        first_name="Jane", last_name="Doe", email=email,
        policy_number=unique("POL").upper(),
    )
    resp.assert_ok()
    assert resp.body["email"] == email
    assert "id" in resp.body


def test_create_customer_requires_auth(client: GartnerClient):
    resp = client.create_customer(first_name="X", last_name="Y", email="z@z.z")
    assert resp.status in (401, 403)


def test_open_claim_generates_claim_number(authed_client: GartnerClient, fresh_customer: dict):
    resp = authed_client.create_claim(
        customer_id=fresh_customer["id"],
        claim_type="property",
        amount_requested=2500.00,
        summary="Pipe burst, water damage to ground floor",
        priority="high",
    )
    resp.assert_ok()
    assert resp.body["claim_number"].startswith("CLM-")
    assert resp.body["status"] == "new"
    assert resp.body["priority"] == "high"
    assert resp.body["sla_due_at"] > resp.body["opened_at"]


def test_claim_priority_drives_sla(authed_client: GartnerClient, fresh_customer: dict):
    urgent = authed_client.create_claim(
        customer_id=fresh_customer["id"], claim_type="auto",
        amount_requested=100.0, summary="Urgent test", priority="urgent",
    ).assert_ok().body
    medium = authed_client.create_claim(
        customer_id=fresh_customer["id"], claim_type="auto",
        amount_requested=100.0, summary="Medium test", priority="medium",
    ).assert_ok().body
    # urgent SLA window must be tighter than medium
    assert (urgent["sla_due_at"] - urgent["opened_at"]) < (medium["sla_due_at"] - medium["opened_at"])


def test_open_claim_requires_existing_customer(authed_client: GartnerClient):
    resp = authed_client.create_claim(
        customer_id=999_999_999,
        claim_type="auto",
        amount_requested=100.0,
        summary="Should fail",
    )
    # Either platform-level FK rejection (400) or our precondition (404)
    assert resp.status in (400, 404)


def test_get_claim_includes_customer_join(authed_client: GartnerClient, open_claim: dict):
    resp = authed_client.get_claim(open_claim["id"])
    resp.assert_ok()
    assert resp.body["id"] == open_claim["id"]
    assert "customer_name" in resp.body
    assert "customer_email" in resp.body


def test_get_missing_claim_returns_error(authed_client: GartnerClient):
    """Platform-level FK validation rejects with 400 before our 404 precondition runs."""
    resp = authed_client.get_claim(999_999_999)
    assert resp.status in (400, 404), f"unexpected status {resp.status}: {resp.body}"


def test_list_claims_with_filter(authed_client: GartnerClient, open_claim: dict):
    resp = authed_client.list_claims(status="new", per_page=50)
    resp.assert_ok()
    ids = {c["id"] for c in resp.body["items"]}
    assert open_claim["id"] in ids


def test_patch_claim_status(authed_client: GartnerClient, open_claim: dict):
    resp = authed_client.update_claim(open_claim["id"], status="in_review")
    resp.assert_ok()
    assert resp.body["status"] == "in_review"


def test_patch_claim_no_changes_rejected(authed_client: GartnerClient, open_claim: dict):
    resp = authed_client.update_claim(open_claim["id"])
    resp.assert_status(400)


def test_patch_closed_status_sets_closed_at(authed_client: GartnerClient, open_claim: dict):
    resp = authed_client.update_claim(open_claim["id"], status="closed", note="Done")
    resp.assert_ok()
    assert resp.body["status"] == "closed"
    assert resp.body["closed_at"] > 0


def test_timeline_grows_with_status_changes(authed_client: GartnerClient, open_claim: dict):
    authed_client.update_claim(open_claim["id"], status="in_review").assert_ok()
    authed_client.update_claim(open_claim["id"], note="Investigation in progress").assert_ok()
    resp = authed_client.claim_timeline(open_claim["id"])
    resp.assert_ok()
    types = [e["event_type"] for e in resp.body["items"]]
    assert "created" in types
    assert "status_changed" in types
    assert "note_added" in types


def test_add_custom_event(authed_client: GartnerClient, open_claim: dict):
    resp = authed_client.add_claim_event(
        open_claim["id"], event_type="note_added", message="Customer called to follow up",
    )
    resp.assert_ok()
    assert resp.body["event_type"] == "note_added"

    timeline = authed_client.claim_timeline(open_claim["id"]).assert_ok()
    msgs = [e["message"] for e in timeline.body["items"]]
    assert "Customer called to follow up" in msgs
