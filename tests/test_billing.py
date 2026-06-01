"""Billing & Payments workspace (workspace 2) - invoices, payments."""
import pytest

from conftest import GartnerClient, unique

pytestmark = pytest.mark.billing


def test_create_inbound_invoice(client: GartnerClient):
    resp = client.billing_create_invoice(
        customer_id=42,
        claim_ref=unique("CLM").upper(),
        direction="inbound",
        amount=1234.56,
        description="Test inbound payout",
        due_in_days=30,
    )
    resp.assert_ok()
    inv = resp.body
    assert inv["amount"] == 1234.56
    assert inv["direction"] == "inbound"
    assert inv["status"] == "issued"
    assert inv["currency"] == "USD"
    assert inv["due_at"] > inv["created_at"]


def test_create_outbound_invoice(client: GartnerClient):
    resp = client.billing_create_invoice(
        customer_id=42, direction="outbound", amount=99.0, description="Premium",
    )
    resp.assert_ok()
    assert resp.body["direction"] == "outbound"


def test_list_invoices_filter_by_customer(client: GartnerClient):
    cust_id = 100_000 + (hash(unique("cust")) % 1_000_000)
    client.billing_create_invoice(
        customer_id=cust_id, direction="inbound", amount=10.0,
    ).assert_ok()
    client.billing_create_invoice(
        customer_id=cust_id, direction="outbound", amount=20.0,
    ).assert_ok()
    resp = client.billing_list_invoices(customer_id=cust_id)
    resp.assert_ok()
    items = resp.body["items"]
    assert len(items) == 2
    assert all(i["customer_id"] == cust_id for i in items)


def test_list_invoices_filter_by_claim_ref(client: GartnerClient):
    claim_ref = unique("CLM").upper()
    client.billing_create_invoice(
        customer_id=42, claim_ref=claim_ref, direction="inbound", amount=500,
    ).assert_ok()
    resp = client.billing_list_invoices(claim_ref=claim_ref)
    resp.assert_ok()
    assert len(resp.body["items"]) == 1
    assert resp.body["items"][0]["claim_ref"] == claim_ref


def test_get_invoice_includes_payments_array(client: GartnerClient):
    created = client.billing_create_invoice(
        customer_id=42, direction="inbound", amount=100.0,
    ).assert_ok()
    fetched = client.billing_get_invoice(created.body["id"])
    fetched.assert_ok()
    assert fetched.body["invoice"]["id"] == created.body["id"]
    assert fetched.body["payments"] == []


def test_pay_invoice_records_payment_and_updates_status(client: GartnerClient):
    created = client.billing_create_invoice(
        customer_id=42, direction="inbound", amount=200.0,
    ).assert_ok()
    inv_id = created.body["id"]
    paid = client.billing_pay_invoice(inv_id, method="wire")
    paid.assert_ok()
    assert paid.body["invoice"]["status"] == "paid"
    assert paid.body["invoice"]["paid_at"] > 0
    assert paid.body["payment"]["amount"] == 200.0
    assert paid.body["payment"]["method"] == "wire"


def test_pay_invoice_with_partial_amount(client: GartnerClient):
    created = client.billing_create_invoice(
        customer_id=42, direction="inbound", amount=500.0,
    ).assert_ok()
    paid = client.billing_pay_invoice(created.body["id"], amount=300.0, method="ach")
    paid.assert_ok()
    assert paid.body["payment"]["amount"] == 300.0


def test_cannot_pay_already_paid_invoice(client: GartnerClient):
    created = client.billing_create_invoice(
        customer_id=42, direction="inbound", amount=50.0,
    ).assert_ok()
    inv_id = created.body["id"]
    client.billing_pay_invoice(inv_id, method="manual").assert_ok()
    second = client.billing_pay_invoice(inv_id, method="manual")
    second.assert_status(400)


def test_get_missing_invoice_returns_404(client: GartnerClient):
    resp = client.billing_get_invoice(999_999_999)
    resp.assert_status(404)


def test_pay_missing_invoice_returns_404(client: GartnerClient):
    resp = client.billing_pay_invoice(999_999_999, method="manual")
    resp.assert_status(404)
