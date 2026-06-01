#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOLUTION="$ROOT_DIR/demo/solutions/rules_catastrophe/api/rules/decisions_evaluate_post.xs"
TARGET="$ROOT_DIR/rules_decisioning/api/rules/decisions_evaluate_post.xs"

cp "$SOLUTION" "$TARGET"
echo "Applied catastrophe routing rule to:"
echo "  $TARGET"
