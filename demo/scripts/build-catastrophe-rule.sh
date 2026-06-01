#!/usr/bin/env bash
# Demo build path ONLY: apply XS locally, validate XanoScript, push to ephemeral sandbox for review.
# Does NOT run runtime tests and does NOT push to live workspace 7.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RULES_PROFILE="${XANO_RULES_PROFILE:-default}"

echo "=== Catastrophe rule demo build (sandbox only) ==="
echo

"$ROOT_DIR/demo/scripts/apply-catastrophe-rule.sh"
echo

echo "Validating XanoScript..."
xano validate -d "$ROOT_DIR/rules_decisioning"
echo

echo "Preview sandbox push..."
"$ROOT_DIR/demo/scripts/push-rules-sandbox.sh" --dry-run
echo

echo "Pushing to ephemeral sandbox and opening review..."
"$ROOT_DIR/demo/scripts/push-rules-sandbox.sh"
echo

echo "Done. Test in the sandbox review UI, then promote to Rules & Decisioning."
echo "No runtime tests were run. Review/promote from the ephemeral sandbox."
