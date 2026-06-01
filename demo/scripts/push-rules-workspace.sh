#!/usr/bin/env bash
set -euo pipefail

PROFILE="${XANO_PROFILE:-default}"
WORKSPACE_ID="${XANO_RULES_WORKSPACE_ID:-7}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ "${CONFIRM_LIVE_PUSH:-}" != "1" ]]; then
  echo "Refusing live workspace push during demo build." >&2
  echo "Use ./demo/scripts/push-rules-sandbox.sh for ephemeral testing." >&2
  echo "To push live after manual promote/rehearsal: CONFIRM_LIVE_PUSH=1 $0" >&2
  exit 1
fi

xano workspace push -p "$PROFILE" -w "$WORKSPACE_ID" -d "$ROOT_DIR/rules_decisioning" --force
