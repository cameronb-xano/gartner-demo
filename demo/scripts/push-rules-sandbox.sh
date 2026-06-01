#!/usr/bin/env bash
set -euo pipefail

BASE_PROFILE="${XANO_PROFILE:-Gartner Demo}"
PROFILE="${XANO_RULES_PROFILE:-Gartner Demo Rules}"
WORKSPACE_ID="${XANO_RULES_WORKSPACE_ID:-7}"
CONFIG_PATH="${XANO_CONFIG:-$HOME/.xano/credentials.yaml}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_DIR="$ROOT_DIR/rules_decisioning"
STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/xano-rules-sandbox.XXXXXX")"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

cleanup() {
  rm -rf "$STAGE_DIR"
}
trap cleanup EXIT

if ! xano profile me -p "$PROFILE" >/dev/null 2>&1; then
  read -r INSTANCE_ORIGIN ACCESS_TOKEN < <(
    BASE_PROFILE="$BASE_PROFILE" CONFIG_PATH="$CONFIG_PATH" ruby -ryaml -e '
      config = YAML.load_file(ENV.fetch("CONFIG_PATH"))
      profile = config.fetch("profiles").fetch(ENV.fetch("BASE_PROFILE"))
      puts [profile.fetch("instance_origin"), profile.fetch("access_token")].join(" ")
    '
  )
  xano profile create "$PROFILE" -i "$INSTANCE_ORIGIN" -t "$ACCESS_TOKEN" -w "$WORKSPACE_ID" >/dev/null
else
  xano profile edit "$PROFILE" -w "$WORKSPACE_ID" >/dev/null
fi

mkdir -p "$STAGE_DIR/api/rules"
cp "$SOURCE_DIR/api/rules/api_group.xs" "$STAGE_DIR/api/rules/api_group.xs"
cp "$SOURCE_DIR/api/rules/auto_approval_get.xs" "$STAGE_DIR/api/rules/auto_approval_get.xs"
cp "$SOURCE_DIR/api/rules/decisions_evaluate_post.xs" "$STAGE_DIR/api/rules/decisions_evaluate_post.xs"

echo "Staged Rules & Decisioning change for sandbox:"
echo "  $STAGE_DIR/api/rules/api_group.xs"
echo "  $STAGE_DIR/api/rules/auto_approval_get.xs"
echo "  $STAGE_DIR/api/rules/decisions_evaluate_post.xs"
echo

if [[ "$DRY_RUN" == "true" ]]; then
  xano sandbox push -d "$STAGE_DIR" -p "$PROFILE" --dry-run
else
  xano sandbox push -d "$STAGE_DIR" -p "$PROFILE" --review
fi
