#!/usr/bin/env bash
set -euo pipefail

PROFILE="${XANO_PROFILE:-default}"
RULES_PROFILE="${XANO_RULES_PROFILE:-default}"
WORKSPACE_ID="${XANO_RULES_WORKSPACE_ID:-7}"
CLAIMS_WORKSPACE_ID="${XANO_CLAIMS_WORKSPACE_ID:-1}"
BASE_URL="${GARTNER_BASE_URL:-https://xjik-uiot-gpzk.n7d.xano.io}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASELINE="$ROOT_DIR/demo/baseline/rules_decisioning/api/rules/decisions_evaluate_post.xs"
TARGET="$ROOT_DIR/rules_decisioning/api/rules/decisions_evaluate_post.xs"

cp "$BASELINE" "$TARGET"

echo "Reset Rules & Decisioning to baseline routing."
echo "Pushing baseline to workspace $WORKSPACE_ID..."
xano workspace push -p "$PROFILE" -w "$WORKSPACE_ID" -d "$ROOT_DIR/rules_decisioning" --force

echo "Pushing Customer Claims baseline with escalation endpoint live..."
xano workspace push -p "$PROFILE" -w "$CLAIMS_WORKSPACE_ID" -d "$ROOT_DIR/tickets_and_claims" --force

echo "Resetting claim 99 record and timeline..."
curl -fsS -X POST "$BASE_URL/api:gartner-claims/claims/demo/reset" \
  -H "Content-Type: application/json" \
  -d '{"confirm":"RESET_CLAIM_99","claim_id":99}' >/dev/null

echo "Clearing sandbox session..."
xano sandbox reset -p "$RULES_PROFILE" --force >/dev/null || true

echo "Reset complete. Claim 99 should be new/high/unassigned; live escalation should route it to property_specialist until the catastrophe rule is promoted."
