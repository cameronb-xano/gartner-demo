#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
This script is intentionally disabled.

The recorded demo requires POST /claims/{claim_id}/escalate to exist in the
default Customer Claims workspace so normal routing can be shown before the
Rules & Decisioning prompt changes the outcome.

Use ./demo/demo_reset.sh to restore the demo baseline instead.
EOF

exit 1
