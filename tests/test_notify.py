"""Notifications workspace (workspace 5) - templates, send, delivery log."""
import pytest

from conftest import GartnerClient, unique

pytestmark = pytest.mark.notify


def test_list_templates_returns_seeded_set(client: GartnerClient):
    resp = client.notify_list_templates()
    resp.assert_ok()
    names = {t["name"] for t in resp.body}
    expected = {"claim_opened", "claim_approved", "claim_paid", "claim_denied"}
    assert expected.issubset(names), f"missing templates: {expected - names}"


def test_filter_templates_by_channel(client: GartnerClient):
    resp = client.notify_list_templates(channel="email")
    resp.assert_ok()
    assert all(t["channel"] == "email" for t in resp.body)


def test_upsert_template(client: GartnerClient):
    name = unique("tpl")
    resp = client.notify_create_template(
        name=name,
        channel="email",
        subject="Hi {{customer_name}}",
        body="Test body {{foo}}",
        is_active=True,
    )
    resp.assert_ok()
    assert resp.body["name"] == name

    update = client.notify_create_template(
        name=name, channel="email", subject="Hi {{customer_name}} v2", body="Test body v2",
    )
    update.assert_ok()
    assert update.body["subject"] == "Hi {{customer_name}} v2"


def test_send_renders_template_vars(client: GartnerClient):
    resp = client.notify_send(
        customer_id=42,
        recipient="recipient@test.com",
        template_name="claim_opened",
        channel="email",
        vars={"customer_name": "Alex", "claim_number": "CLM-X-001", "amount": "999"},
        source="test",
    )
    resp.assert_ok()
    n = resp.body
    assert n["status"] == "sent"
    assert n["sent_at"] > 0
    assert "Alex" in n["body"]
    assert "CLM-X-001" in n["body"]
    assert "CLM-X-001" in n["subject"]


def test_send_with_unknown_template_still_logs(client: GartnerClient):
    resp = client.notify_send(
        customer_id=42,
        recipient="x@test.com",
        template_name="totally-not-a-template-" + unique("x"),
        channel="email",
        vars={},
    )
    resp.assert_ok()
    assert resp.body["status"] == "sent"
    assert "Template not found" in resp.body["body"]


def test_notification_log_filter_by_template(client: GartnerClient):
    name = "test_tpl_" + unique("x").replace("-", "_")
    client.notify_create_template(
        name=name, channel="email", subject="t", body="b",
    ).assert_ok()
    client.notify_send(
        customer_id=99, recipient="x@x.com", template_name=name, channel="email",
    ).assert_ok()

    resp = client.notify_list(template_name=name)
    resp.assert_ok()
    assert resp.body["itemsReceived"] >= 1
    assert all(item["template_name"] == name for item in resp.body["items"])


def test_send_records_source(client: GartnerClient):
    name = "src_tpl_" + unique("x").replace("-", "_")
    client.notify_create_template(name=name, channel="email", subject="s", body="b").assert_ok()
    resp = client.notify_send(
        customer_id=99,
        recipient="x@x.com",
        template_name=name,
        channel="email",
        source="test-suite",
    )
    resp.assert_ok()
    assert resp.body["source"] == "test-suite"
