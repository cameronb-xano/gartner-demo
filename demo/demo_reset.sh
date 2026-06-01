#!/usr/bin/env bash
# Reset the demo state so the recorded catastrophe-routing build moment is fresh.
#
# - Keeps /escalate live in Customer Claims so the normal behavior is visible
# - Resets Rules & Decisioning to baseline routing
# - Resets claim 99 so it can be escalated before and after the rules change
#
# Usage:
#   ./demo/demo_reset.sh

set -e
cd "$(dirname "$0")/.."

ROOT="$(pwd)"
PROFILE="${XANO_PROFILE:-default}"
RULES_PROFILE="${XANO_RULES_PROFILE:-default}"
WS_ID=1
RULES_WS_ID="${XANO_RULES_WORKSPACE_ID:-7}"
ESCALATE_FILE="api/claims/escalate_post.xs"
BASELINE_RULES="demo/baseline/rules_decisioning/api/rules/decisions_evaluate_post.xs"
ACTIVE_RULES="rules_decisioning/api/rules/decisions_evaluate_post.xs"
BASE_URL="${GARTNER_BASE_URL:-https://xjik-uiot-gpzk.n7d.xano.io}"

echo "→ Verifying local escalate file is present..."
if [ ! -f "tickets_and_claims/${ESCALATE_FILE}" ]; then
  echo "  ERROR: tickets_and_claims/${ESCALATE_FILE} missing — re-create before resetting"
  exit 1
fi
echo "  ✓ found"

echo
echo "→ Publishing Customer Claims baseline with escalate live..."
xano workspace push -d "tickets_and_claims" -p "${PROFILE}" -w "${WS_ID}" --force 2>&1 | tail -5

echo
echo "→ Resetting Rules & Decisioning to baseline routing..."
cp "${BASELINE_RULES}" "${ACTIVE_RULES}"
xano workspace push -d "rules_decisioning" -p "${PROFILE}" -w "${RULES_WS_ID}" --force 2>&1 | tail -5

echo
echo "→ Resetting claim 99..."
curl -fsS -X POST "${BASE_URL}/api:gartner-claims/claims/demo/reset" \
  -H "Content-Type: application/json" \
  -d '{"confirm":"RESET_CLAIM_99","claim_id":99}' >/dev/null

echo
echo "→ Clearing Rules sandbox session..."
xano sandbox reset --force -p "${RULES_PROFILE}" >/dev/null || true

echo
echo "✓ Demo state reset. For recording:"
echo
echo "  1. Show normal escalation behavior with the live endpoint:"
echo "       ./demo/demo_call.sh 99"
echo "  2. Prompt for the catastrophe routing change in Rules & Decisioning."
echo "  3. Push the Rules change to sandbox, review, promote, then escalate claim 99 again."
