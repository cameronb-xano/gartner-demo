"""Shared fixtures and helpers for the Gartner Demo test suite.

All tests hit the live Xano instance over HTTP. Each test that mutates state
generates unique values (timestamp-based) so tests don't collide across runs.
"""
from __future__ import annotations

import os
import time
import uuid
from dataclasses import dataclass
from typing import Any, Optional

import pytest
import requests

BASE = os.environ.get(
    "GARTNER_BASE_URL",
    "https://x5oh-bynb-yevw.n7d.xano.io",
)

URLS = {
    "tickets": f"{BASE}/api:gartner-claims",
    "tickets_auth": f"{BASE}/api:gartner-claims-auth",
    "iam": f"{BASE}/api:gartner-iam",
    "profiling": f"{BASE}/api:gartner-profiling",
    "billing": f"{BASE}/api:gartner-billing",
    "notify": f"{BASE}/api:gartner-notify",
}


@dataclass
class ApiResponse:
    """Lightweight wrapper that exposes status + parsed body."""

    status: int
    body: Any
    raw: requests.Response

    def assert_ok(self, msg: str = "") -> "ApiResponse":
        assert 200 <= self.status < 300, (
            f"{msg or 'expected 2xx'} but got {self.status}: {self.body!r}"
        )
        return self

    def assert_status(self, expected: int, msg: str = "") -> "ApiResponse":
        assert self.status == expected, (
            f"{msg or f'expected {expected}'} but got {self.status}: {self.body!r}"
        )
        return self


class GartnerClient:
    """Tiny HTTP client over the 5 workspaces. Pretty errors on failure."""

    def __init__(self) -> None:
        self.session = requests.Session()
        self.token: Optional[str] = None

    def _headers(self, extra: Optional[dict] = None) -> dict:
        headers = {"Content-Type": "application/json"}
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        if extra:
            headers.update(extra)
        return headers

    def _call(
        self,
        method: str,
        url: str,
        *,
        json: Any = None,
        params: Optional[dict] = None,
        no_auth: bool = False,
    ) -> ApiResponse:
        headers = self._headers()
        if no_auth:
            headers.pop("Authorization", None)
        resp = self.session.request(
            method, url, headers=headers, json=json, params=params, timeout=15
        )
        try:
            body = resp.json()
        except ValueError:
            body = resp.text
        return ApiResponse(status=resp.status_code, body=body, raw=resp)

    # ---- Tickets & Claims ----
    def signup(self, email: str, password: str, name: str = "Test Agent", role: str = "agent") -> ApiResponse:
        return self._call("POST", f"{URLS['tickets_auth']}/signup", json={
            "name": name, "email": email, "password": password, "role": role,
        }, no_auth=True)

    def login(self, email: str, password: str) -> ApiResponse:
        return self._call("POST", f"{URLS['tickets_auth']}/login", json={
            "email": email, "password": password,
        }, no_auth=True)

    def me(self) -> ApiResponse:
        return self._call("GET", f"{URLS['tickets_auth']}/me")

    def list_customers(self, **params) -> ApiResponse:
        return self._call("GET", f"{URLS['tickets']}/customers", params=params)

    def create_customer(self, **fields) -> ApiResponse:
        return self._call("POST", f"{URLS['tickets']}/customers", json=fields)

    def list_claims(self, **params) -> ApiResponse:
        return self._call("GET", f"{URLS['tickets']}/claims", params=params)

    def create_claim(self, **fields) -> ApiResponse:
        return self._call("POST", f"{URLS['tickets']}/claims", json=fields)

    def get_claim(self, claim_id: int) -> ApiResponse:
        return self._call("GET", f"{URLS['tickets']}/claims/{claim_id}")

    def update_claim(self, claim_id: int, **fields) -> ApiResponse:
        return self._call("PATCH", f"{URLS['tickets']}/claims/{claim_id}", json=fields)

    def claim_timeline(self, claim_id: int, **params) -> ApiResponse:
        return self._call("GET", f"{URLS['tickets']}/claims/{claim_id}/timeline", params=params)

    def add_claim_event(self, claim_id: int, **fields) -> ApiResponse:
        return self._call("POST", f"{URLS['tickets']}/claims/{claim_id}/events", json=fields)

    def escalate_claim(self, claim_id: int, reason: Optional[str] = None) -> ApiResponse:
        payload = {}
        if reason is not None:
            payload["reason"] = reason
        return self._call("POST", f"{URLS['tickets']}/claims/{claim_id}/escalate", json=payload)

    def claim_360(self, claim_id: int) -> ApiResponse:
        return self._call("GET", f"{URLS['tickets']}/claims/{claim_id}/360")

    def customer_insights(self, customer_id: int) -> ApiResponse:
        return self._call("GET", f"{URLS['tickets']}/customers/{customer_id}/insights")

    # ---- IAM ----
    def iam_signup(self, email: str, password: str, **extra) -> ApiResponse:
        return self._call("POST", f"{URLS['iam']}/signup", json={
            "email": email, "password": password, "name": extra.get("name", "IAM User"),
            "role": extra.get("role", "agent"),
        }, no_auth=True)

    def iam_login(self, email: str, password: str, source: Optional[str] = None) -> ApiResponse:
        payload = {"email": email, "password": password}
        if source:
            payload["source"] = source
        return self._call("POST", f"{URLS['iam']}/login", json=payload, no_auth=True)

    def iam_verify(self, token: str) -> ApiResponse:
        return self._call("POST", f"{URLS['iam']}/verify", json={"token": token}, no_auth=True)

    def iam_get_user(self, user_id: int) -> ApiResponse:
        return self._call("GET", f"{URLS['iam']}/users/{user_id}", no_auth=True)

    # ---- Profiling ----
    def profiling_create_customer(self, **fields) -> ApiResponse:
        return self._call("POST", f"{URLS['profiling']}/customers", json=fields, no_auth=True)

    def profiling_list_customers(self, **params) -> ApiResponse:
        return self._call("GET", f"{URLS['profiling']}/customers", params=params, no_auth=True)

    def profiling_get_customer(self, customer_id: int) -> ApiResponse:
        return self._call("GET", f"{URLS['profiling']}/customers/{customer_id}", no_auth=True)

    def profiling_record_event(self, **fields) -> ApiResponse:
        return self._call("POST", f"{URLS['profiling']}/events", json=fields, no_auth=True)

    # ---- Billing ----
    def billing_list_invoices(self, **params) -> ApiResponse:
        return self._call("GET", f"{URLS['billing']}/invoices", params=params, no_auth=True)

    def billing_create_invoice(self, **fields) -> ApiResponse:
        return self._call("POST", f"{URLS['billing']}/invoices", json=fields, no_auth=True)

    def billing_get_invoice(self, invoice_id: int) -> ApiResponse:
        return self._call("GET", f"{URLS['billing']}/invoices/{invoice_id}", no_auth=True)

    def billing_pay_invoice(self, invoice_id: int, **fields) -> ApiResponse:
        return self._call("POST", f"{URLS['billing']}/invoices/{invoice_id}/pay", json=fields, no_auth=True)

    # ---- Notify ----
    def notify_send(self, **fields) -> ApiResponse:
        return self._call("POST", f"{URLS['notify']}/send", json=fields, no_auth=True)

    def notify_list_templates(self, **params) -> ApiResponse:
        return self._call("GET", f"{URLS['notify']}/templates", params=params, no_auth=True)

    def notify_create_template(self, **fields) -> ApiResponse:
        return self._call("POST", f"{URLS['notify']}/templates", json=fields, no_auth=True)

    def notify_list(self, **params) -> ApiResponse:
        return self._call("GET", f"{URLS['notify']}/notifications", params=params, no_auth=True)


# ---------- pytest fixtures ----------

def _unique(prefix: str) -> str:
    """Generate a unique value for test isolation."""
    return f"{prefix}-{int(time.time() * 1000)}-{uuid.uuid4().hex[:6]}"


@pytest.fixture(scope="session")
def base_url() -> str:
    return BASE


@pytest.fixture
def client() -> GartnerClient:
    """Fresh, unauthenticated client per test."""
    return GartnerClient()


@pytest.fixture
def authed_client() -> GartnerClient:
    """Client signed in as a fresh agent (Tickets workspace)."""
    c = GartnerClient()
    email = _unique("agent") + "@gartner.test"
    resp = c.signup(email=email, password="Test1234!", name="Test Agent")
    resp.assert_ok("signup failed")
    c.token = resp.body["token"]
    return c


@pytest.fixture
def iam_authed_client() -> GartnerClient:
    """Client signed in via IAM workspace (different user table)."""
    c = GartnerClient()
    email = _unique("iam-agent") + "@gartner.test"
    resp = c.iam_signup(email=email, password="Test1234!", name="IAM Agent")
    resp.assert_ok("iam signup failed")
    c.token = resp.body["token"]
    return c


@pytest.fixture
def fresh_customer(authed_client: GartnerClient) -> dict:
    """Create a fresh customer (in both Tickets and Profiling) and return it."""
    email = _unique("cust") + "@gartner.test"
    resp = authed_client.create_customer(
        first_name="Test",
        last_name="Customer",
        email=email,
        phone="+1-555-0100",
        policy_number=_unique("POL").upper(),
    )
    resp.assert_ok("customer create failed")
    return resp.body


@pytest.fixture
def open_claim(authed_client: GartnerClient, fresh_customer: dict) -> dict:
    """Open a fresh claim for the fresh customer and return it."""
    resp = authed_client.create_claim(
        customer_id=fresh_customer["id"],
        claim_type="auto",
        amount_requested=1500.00,
        summary="Test claim opened by automated suite",
        priority="medium",
    )
    resp.assert_ok("claim create failed")
    return resp.body


def unique(prefix: str) -> str:
    """Public helper for test files."""
    return _unique(prefix)
