#!/usr/bin/env bash
# verify_current.sh — compara aso-pipeline/current/metadata/ vs ASC live state.
#
# Sai com código 0 se tudo bater, 1 se houver divergência.
# Usar como pre-commit hook ou rodar antes de cada deploy:
#
#   ./scripts/verify_current.sh           # human-readable diff
#   ./scripts/verify_current.sh --strict  # exit 1 em qualquer diff (CI mode)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$SCRIPT_DIR/verify_current.py" "$@"
