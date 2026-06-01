#!/usr/bin/env bash
# Convenience runner for the Gartner Demo test suite.
#
# Usage:
#   ./run.sh                    # run everything
#   ./run.sh -m iam             # only IAM workspace tests
#   ./run.sh -m "not slow"      # skip e2e tests
#   ./run.sh -k claim           # filter by name
#   ./run.sh -n auto            # parallel via pytest-xdist
#
# All flags pass through to pytest.

set -e
cd "$(dirname "$0")"

if [ ! -d ".venv" ]; then
  echo "→ Creating venv..."
  python3 -m venv .venv
  ./.venv/bin/pip install --quiet --upgrade pip
  ./.venv/bin/pip install --quiet -r requirements.txt
fi

exec ./.venv/bin/pytest "$@"
