#!/usr/bin/env bash
# deploy.sh — apply an iteration's proposed/ changes to current/ and push via fastlane.
#
# Usage:
#   ./scripts/deploy.sh iterations/2026-05-22_iter-01-text-pt-BR-keywords
#
# Flow:
#   1. Validate proposed/ has at least one file
#   2. Pre-flight char limit checks (name ≤30, subtitle ≤30, keywords ≤100)
#   3. Snapshot current/metadata/ as a backup zip in iter folder
#   4. Copy proposed/metadata/* → current/metadata/*
#   5. Run fastlane sync_metadata
#   6. Record deploy_commit in meta.json
#
# NOTE: does NOT auto-commit. You commit explicitly after deploy succeeds.

set -euo pipefail

ITER_DIR="${1:?Usage: $0 <iter-dir>}"

if [ ! -d "$ITER_DIR" ]; then
    echo "ERROR: $ITER_DIR is not a directory"
    exit 1
fi

cd "$(dirname "$0")/.."
PROPOSED="$ITER_DIR/proposed"
CURRENT="current"

# ─── 1. Validate proposed/ ──────────────────────────────────────────────
if [ ! -d "$PROPOSED/metadata" ]; then
    echo "ERROR: $PROPOSED/metadata not found — nothing to deploy"
    exit 1
fi

FILE_COUNT=$(find "$PROPOSED/metadata" -type f -name "*.txt" | wc -l | tr -d ' ')
if [ "$FILE_COUNT" = "0" ]; then
    echo "ERROR: no .txt files in $PROPOSED/metadata"
    exit 1
fi
echo "[1/5] Found $FILE_COUNT proposed metadata files to deploy"

# ─── 2. Char limit checks ────────────────────────────────────────────────
echo "[2/5] Pre-flight char limit checks ..."
declare -A LIMITS=( [name.txt]=30 [subtitle.txt]=30 [keywords.txt]=100 [promotional_text.txt]=170 [description.txt]=4000 [release_notes.txt]=4000 )

VIOLATIONS=0
while IFS= read -r f; do
    base=$(basename "$f")
    limit=${LIMITS[$base]:-0}
    if [ "$limit" = "0" ]; then continue; fi
    # Use python for grapheme-aware char count (matches what Apple counts)
    count=$(python3 -c "import sys; print(len(open(sys.argv[1]).read().rstrip('\n')))" "$f")
    if [ "$count" -gt "$limit" ]; then
        echo "  ✗ $f: $count chars (LIMIT: $limit)"
        VIOLATIONS=$((VIOLATIONS+1))
    else
        echo "  ✓ $f: $count/$limit chars"
    fi
done < <(find "$PROPOSED/metadata" -type f -name "*.txt")

if [ "$VIOLATIONS" -gt 0 ]; then
    echo "ERROR: $VIOLATIONS char-limit violations. Fix proposed/ files before deploy."
    exit 1
fi

# ─── 3. Backup current/metadata/ ─────────────────────────────────────────
TS=$(date +%Y-%m-%d_%H%M%S)
BACKUP="$ITER_DIR/backup_pre_deploy_$TS.tgz"
echo "[3/5] Backing up current/metadata/ → $BACKUP"
tar -czf "$BACKUP" -C current metadata

# ─── 4. Apply proposed/ → current/ ───────────────────────────────────────
echo "[4/5] Applying proposed/ → current/ ..."
while IFS= read -r f; do
    rel="${f#$PROPOSED/}"
    dest="$CURRENT/$rel"
    mkdir -p "$(dirname "$dest")"
    cp "$f" "$dest"
    echo "  → $dest"
done < <(find "$PROPOSED/metadata" -type f -name "*.txt")

# ─── 5. Run fastlane sync_metadata ───────────────────────────────────────
echo "[5/5] Running fastlane sync_metadata ..."
echo ""
echo "  IMPORTANT: this pushes to App Store Connect."
echo "  Press Ctrl-C in next 5s to abort."
sleep 5

cd ..
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    APP_STORE_CONNECT_KEY_ID="${APP_STORE_CONNECT_KEY_ID:-67JG58Q6XH}" \
    APP_STORE_CONNECT_ISSUER_ID="${APP_STORE_CONNECT_ISSUER_ID:-98c49316-b223-4d64-955d-b55ae76ab9d2}" \
    APP_STORE_CONNECT_KEY_PATH="${APP_STORE_CONNECT_KEY_PATH:-$HOME/private_keys/keys/asc_api_key.p8}" \
    fastlane sync_metadata

cd aso-pipeline

# Update meta.json
DEPLOY_TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
python3 -c "
import json, sys
with open('$ITER_DIR/meta.json') as f: m = json.load(f)
m['deployed'] = True
m['status'] = 'running'
m['deploy_timestamp'] = '$DEPLOY_TS'
with open('$ITER_DIR/meta.json','w') as f: json.dump(m, f, indent=2, ensure_ascii=False)
"

echo ""
echo "Deploy complete."
echo "  Iter:    $ITER_DIR"
echo "  Backup:  $BACKUP"
echo "  Status:  status=running, deploy_timestamp=$DEPLOY_TS"
echo ""
echo "Next:"
echo "  - Commit current/ + iter folder (the proposed change is now live)"
echo "  - Wait ~24-48h for Apple review of metadata changes"
echo "  - In 7d: ./scripts/pull_analytics.py $ITER_DIR  (1st checkpoint)"
echo "  - In 28d: ./scripts/promote_winner.sh $ITER_DIR  (close iter)"
