#!/usr/bin/env bash
#
# Reset the demo to a clean state where:
#   - All workspaces are deployed and aligned
#   - Sandbox has everything EXCEPT stats_get.xs
#   - The demo can show: edit file → sandbox push → review → promote → live
#
# Usage:
#   ./reset_demo.sh            # full reset (resets sandbox, re-stages)
#   ./reset_demo.sh --check    # just print current pending state, no changes

set -e
PROFILE="Gartner Demo"
WORKSPACE_DIR="$(cd "$(dirname "$0")/.." && pwd)/tickets_and_claims"
DEMO_FILE="api/claims/stats_get.xs"

if [ "$1" = "--check" ]; then
  echo "→ Pending sandbox changes:"
  xano sandbox push -d "$WORKSPACE_DIR" -p "$PROFILE" --dry-run 2>&1 | tail -20
  exit 0
fi

echo "→ Resetting sandbox (force, no prompt)..."
xano sandbox reset -p "$PROFILE" -f >/dev/null

echo "→ Restaging sandbox with all files EXCEPT $DEMO_FILE..."
xano sandbox push -d "$WORKSPACE_DIR" -p "$PROFILE" -e "$DEMO_FILE" --force 2>&1 | tail -3

echo
echo "→ Verifying demo state..."
xano sandbox push -d "$WORKSPACE_DIR" -p "$PROFILE" --dry-run 2>&1 | tail -10

echo
echo "✅ Demo ready. The pending change above should be ONLY 'claims/stats GET'."
echo
echo "During the demo, run these commands:"
echo
echo "  # 1. Show what's about to be pushed"
echo "  xano sandbox push -d $WORKSPACE_DIR -p '$PROFILE' --dry-run"
echo
echo "  # 2. Push to sandbox (interactive — audience sees the preview, you type 'y')"
echo "  xano sandbox push -d $WORKSPACE_DIR -p '$PROFILE'"
echo
echo "  # 3. Open the sandbox review/promote screen in browser"
echo "  xano sandbox review -p '$PROFILE'"
echo
echo "  # 4. After clicking 'Promote' in the browser, hit the new endpoint:"
echo "  curl -s 'https://xjik-uiot-gpzk.n7d.xano.io/api:gartner-claims/claims/stats' \\"
echo "       -H 'Authorization: Bearer YOUR_TOKEN' | python3 -m json.tool"
