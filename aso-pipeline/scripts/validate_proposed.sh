#!/usr/bin/env bash
# validate_proposed.sh — pre-deploy lint da pasta proposed/ de uma iteração.
#
# Checa: char counts, lowercase, stopwords, duplicatas com name/subtitle,
# palavras truncadas, e (avisa) palavras que não estão no Astro track.
#
#   ./scripts/validate_proposed.sh iterations/2026-05-22_iter-01-text-pt-BR-keywords
#
# Exit 0 se tudo passa, 1 se há blocker.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$SCRIPT_DIR/validate_proposed.py" "$@"
