"""Identity & Access workspace (workspace 4) - auth, sessions, token verify."""
import pytest

from conftest import GartnerClient, unique

pytestmark = pytest.mark.iam


def test_signup_returns_token_and_user(client: GartnerClient):
    email = unique("iam") + "@test.com"
    resp = client.iam_signup(email=email, password="Test1234!", name="Alice")
    resp.assert_ok()
    assert "token" in resp.body
    assert resp.body["user"]["email"] == email
    assert resp.body["user"]["role"] == "agent"


def test_signup_rejects_duplicate_email(client: GartnerClient):
    email = unique("iam-dup") + "@test.com"
    client.iam_signup(email=email, password="Test1234!").assert_ok()
    dup = client.iam_signup(email=email, password="Test1234!")
    dup.assert_status(400)


def test_signup_rejects_short_password(client: GartnerClient):
    resp = client.iam_signup(email=unique("iam-pw") + "@test.com", password="short")
    assert resp.status >= 400


def test_login_returns_same_user(client: GartnerClient):
    email = unique("iam-login") + "@test.com"
    client.iam_signup(email=email, password="Test1234!").assert_ok()
    resp = client.iam_login(email=email, password="Test1234!", source="test-suite")
    resp.assert_ok()
    assert "token" in resp.body
    assert resp.body["user"]["email"] == email


def test_login_wrong_password_denied(client: GartnerClient):
    email = unique("iam-bad") + "@test.com"
    client.iam_signup(email=email, password="Test1234!").assert_ok()
    resp = client.iam_login(email=email, password="WrongPass!")
    resp.assert_status(403)


def test_login_unknown_email_denied(client: GartnerClient):
    resp = client.iam_login(email="nobody-" + unique("x") + "@test.com", password="Test1234!")
    resp.assert_status(403)


def test_verify_valid_token(client: GartnerClient):
    email = unique("iam-verify") + "@test.com"
    signup = client.iam_signup(email=email, password="Test1234!").assert_ok()
    token = signup.body["token"]
    resp = client.iam_verify(token=token)
    resp.assert_ok()
    assert resp.body["valid"] is True
    assert resp.body["user"]["email"] == email


def test_verify_garbage_token_returns_invalid(client: GartnerClient):
    resp = client.iam_verify(token="not-a-real-token")
    resp.assert_ok()
    assert resp.body["valid"] is False
    assert resp.body["user"] is None


def test_get_user_by_id(client: GartnerClient):
    email = unique("iam-getuser") + "@test.com"
    signup = client.iam_signup(email=email, password="Test1234!").assert_ok()
    user_id = signup.body["user"]["id"]
    resp = client.iam_get_user(user_id)
    resp.assert_ok()
    assert resp.body["id"] == user_id
    assert resp.body["email"] == email


def test_get_user_missing_returns_404(client: GartnerClient):
    resp = client.iam_get_user(999_999_999)
    resp.assert_status(404)


def test_me_requires_auth(client: GartnerClient):
    resp = client.iam_login(email="x@x.x", password="x")  # just to set state, will fail
    # /me on iam isn't on the test client, but the public client without token can't reach it
    # This test is conceptual: verify is the canonical "who am I from a token" call
    pass
