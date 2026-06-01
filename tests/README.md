# Gartner Demo — Test Suite

Local Python/pytest suite that hits the live Xano workspaces over HTTP. Use it
to iterate on backend changes without clicking through the dashboard.

## Layout

```
tests/
├── conftest.py        # GartnerClient + shared fixtures (authed_client, fresh_customer, open_claim)
├── pytest.ini         # markers: iam, profiling, billing, notify, tickets, e2e, slow
├── requirements.txt
├── run.sh             # convenience runner that auto-creates venv
├── test_iam.py        # workspace 4 — auth, sessions, verify
├── test_profiling.py  # workspace 3 — customers, behavior events, segment recalc
├── test_billing.py    # workspace 2 — invoices, payments
├── test_notify.py     # workspace 5 — templates, send, delivery log
├── test_tickets.py    # workspace 1 — claims, tickets, timeline
└── test_e2e.py        # cross-workspace fan-out lifecycle
```

## Running

```bash
cd tests
./run.sh                     # everything
./run.sh -m iam              # only IAM tests
./run.sh -m "not slow"       # skip e2e tests
./run.sh -k claim            # only tests with "claim" in the name
./run.sh -n 4                # parallel (4 workers, via pytest-xdist)
./run.sh test_tickets.py     # one file
./run.sh -x                  # stop at first failure
./run.sh --lf                # rerun last failures
```

## Markers

| Marker | What it covers |
|---|---|
| `iam` | Identity & Access workspace |
| `profiling` | Customer Profiling workspace |
| `billing` | Billing & Payments workspace |
| `notify` | Notifications workspace |
| `tickets` | Tickets & Claims workspace |
| `e2e` | End-to-end cross-workspace flows |
| `slow` | Tests that take a few seconds (network heavy, includes all e2e) |

## Targeting a different instance

The base URL is set in `conftest.py` and can be overridden via env var:

```bash
GARTNER_BASE_URL="https://your-other-instance.n7d.xano.io" ./run.sh
```

## Iteration loop

```bash
# 1. Edit a .xs file under ../tickets_and_claims/, ../billing_and_payments/, etc.
# 2. Push to Xano:
xano workspace push "../tickets_and_claims" -p "Gartner Demo" -w 1 --sync --force
# 3. Re-run targeted tests:
./run.sh -m tickets -x
```

## Test isolation

Every test that mutates state generates unique values via `unique()` (timestamp +
uuid prefix), so tests can run repeatedly against the same instance without
collisions or cleanup. There's no test-database teardown — accumulated test data
stays in the workspaces (intentional, makes the demo feel "real").
