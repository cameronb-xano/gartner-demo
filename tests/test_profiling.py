"""Customer Profiling workspace (workspace 3) - customers, behavior events, segment recalc."""
import pytest

from conftest import GartnerClient, unique

pytestmark = pytest.mark.profiling


def test_create_and_fetch_customer(client: GartnerClient):
    email = unique("prof") + "@test.com"
    create = client.profiling_create_customer(
        first_name="Pat", last_name="Test", email=email, policy_number=unique("POL").upper(),
    )
    create.assert_ok()
    cid = create.body["id"]
    assert create.body["segment"] == "new"

    fetched = client.profiling_get_customer(cid)
    fetched.assert_ok()
    assert fetched.body["customer"]["id"] == cid
    assert fetched.body["customer"]["email"] == email
    assert fetched.body["total_events"] == 0


def test_create_customer_rejects_duplicate_email(client: GartnerClient):
    email = unique("prof-dup") + "@test.com"
    client.profiling_create_customer(first_name="A", last_name="B", email=email).assert_ok()
    dup = client.profiling_create_customer(first_name="A", last_name="B", email=email)
    dup.assert_status(400)


def test_get_missing_customer_returns_404(client: GartnerClient):
    resp = client.profiling_get_customer(999_999_999)
    resp.assert_status(404)


def test_event_ingest_increments_risk(client: GartnerClient):
    email = unique("prof-risk") + "@test.com"
    cust = client.profiling_create_customer(first_name="Risky", last_name="Person", email=email).assert_ok()
    cid = cust.body["id"]
    initial_risk = cust.body["risk_score"]

    resp = client.profiling_record_event(
        customer_id=cid, source="test", event_type="claim_opened", payload={"foo": "bar"},
    )
    resp.assert_ok()
    assert resp.body["customer"]["risk_score"] == initial_risk + 5
    assert resp.body["event"]["event_type"] == "claim_opened"


def test_claim_denied_event_increments_risk_more(client: GartnerClient):
    email = unique("prof-deny") + "@test.com"
    cust = client.profiling_create_customer(first_name="Deny", last_name="Test", email=email).assert_ok()
    cid = cust.body["id"]

    resp = client.profiling_record_event(
        customer_id=cid, source="test", event_type="claim_denied",
    )
    resp.assert_ok()
    assert resp.body["customer"]["risk_score"] == 10


def test_paid_event_grows_lifetime_value(client: GartnerClient):
    email = unique("prof-ltv") + "@test.com"
    cust = client.profiling_create_customer(first_name="LTV", last_name="Test", email=email).assert_ok()
    cid = cust.body["id"]

    client.profiling_record_event(
        customer_id=cid, source="test", event_type="claim_paid",
        payload={"amount": 2500},
    ).assert_ok()
    client.profiling_record_event(
        customer_id=cid, source="test", event_type="payment_received",
        payload={"amount": 750},
    ).assert_ok()

    fetched = client.profiling_get_customer(cid).assert_ok()
    assert fetched.body["customer"]["lifetime_value"] == 3250
    assert fetched.body["total_events"] >= 2


def test_high_value_customer_segment(client: GartnerClient):
    email = unique("prof-hv") + "@test.com"
    cust = client.profiling_create_customer(first_name="High", last_name="Value", email=email).assert_ok()
    cid = cust.body["id"]

    client.profiling_record_event(
        customer_id=cid, source="test", event_type="claim_paid", payload={"amount": 12000},
    ).assert_ok()
    fetched = client.profiling_get_customer(cid).assert_ok()
    assert fetched.body["customer"]["segment"] == "high_value"


def test_at_risk_segment_when_score_high(client: GartnerClient):
    email = unique("prof-risk") + "@test.com"
    cust = client.profiling_create_customer(first_name="At", last_name="Risk", email=email).assert_ok()
    cid = cust.body["id"]
    # 7 denials × 10 = 70, hits at_risk threshold
    for _ in range(7):
        client.profiling_record_event(
            customer_id=cid, source="test", event_type="claim_denied",
        ).assert_ok()
    fetched = client.profiling_get_customer(cid).assert_ok()
    assert fetched.body["customer"]["risk_score"] >= 70
    assert fetched.body["customer"]["segment"] == "at_risk"


def test_event_for_unknown_customer_404(client: GartnerClient):
    resp = client.profiling_record_event(
        customer_id=999_999_999, source="test", event_type="claim_opened",
    )
    resp.assert_status(404)


def test_list_customers_pagination(client: GartnerClient):
    resp = client.profiling_list_customers(per_page=5, page=1)
    resp.assert_ok()
    assert "items" in resp.body
    assert resp.body["perPage"] == 5
