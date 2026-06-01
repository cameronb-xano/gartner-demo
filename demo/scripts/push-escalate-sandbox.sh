#!/usr/bin/env bash
set -euo pipefail

PROFILE="${XANO_PROFILE:-default}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_DIR="$ROOT_DIR/tickets_and_claims"
STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/xano-escalate-sandbox.XXXXXX")"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

cleanup() {
  rm -rf "$STAGE_DIR"
}
trap cleanup EXIT

mkdir -p "$STAGE_DIR/api/claims"
mkdir -p "$STAGE_DIR/function"
mkdir -p "$STAGE_DIR/table"

cp "$SOURCE_DIR/api/claims/api_group.xs" "$STAGE_DIR/api/claims/api_group.xs"
cp "$SOURCE_DIR/api/claims/escalate_post.xs" "$STAGE_DIR/api/claims/escalate_post.xs"
cp "$SOURCE_DIR/function/evaluate_auto_approval.xs" "$STAGE_DIR/function/evaluate_auto_approval.xs"
cp "$SOURCE_DIR/function/log_claim_event.xs" "$STAGE_DIR/function/log_claim_event.xs"
cp "$SOURCE_DIR/function/notify_customer.xs" "$STAGE_DIR/function/notify_customer.xs"
cp "$SOURCE_DIR/function/record_customer_event.xs" "$STAGE_DIR/function/record_customer_event.xs"
cp "$SOURCE_DIR/table/claim.xs" "$STAGE_DIR/table/claim.xs"
cp "$SOURCE_DIR/table/claim_event.xs" "$STAGE_DIR/table/claim_event.xs"

echo "Staged escalation endpoint for sandbox:"
echo "  $STAGE_DIR/api/claims/api_group.xs"
echo "  $STAGE_DIR/api/claims/escalate_post.xs"
echo "  $STAGE_DIR/function/*.xs"
echo "  $STAGE_DIR/table/claim*.xs"
echo
echo "Pushing to Xano sandbox using profile '$PROFILE'..."
if [[ "$DRY_RUN" == "true" ]]; then
  xano sandbox push -d "$STAGE_DIR" -p "$PROFILE" --dry-run
else
  xano sandbox push -d "$STAGE_DIR" -p "$PROFILE" --review
fi
