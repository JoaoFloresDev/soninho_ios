#!/usr/bin/env bash
# promote_winner.sh — close an iteration with a verdict.
#
# Usage:
#   ./scripts/promote_winner.sh <iter-dir> won
#   ./scripts/promote_winner.sh <iter-dir> lost
#   ./scripts/promote_winner.sh <iter-dir> inconclusive
#   ./scripts/promote_winner.sh <iter-dir> reverted
#
# "won" → keeps current/ as-is (proposed/ already in current/ from deploy), updates registry
# "lost" / "reverted" → restores current/ from backup zip, updates registry
# "inconclusive" → keeps current/ but flags hypothesis as needing iteration

set -euo pipefail

ITER_DIR="${1:?Usage: $0 <iter-dir> <won|lost|inconclusive|reverted>}"
VERDICT="${2:?Usage: $0 <iter-dir> <won|lost|inconclusive|reverted>}"

case "$VERDICT" in
    won|lost|inconclusive|reverted) ;;
    *) echo "ERROR: verdict must be one of: won, lost, inconclusive, reverted"; exit 1 ;;
esac

cd "$(dirname "$0")/.."

if [ ! -f "$ITER_DIR/meta.json" ]; then
    echo "ERROR: $ITER_DIR/meta.json not found"
    exit 1
fi

# If "lost" or "reverted" → restore current/ from backup
if [ "$VERDICT" = "lost" ] || [ "$VERDICT" = "reverted" ]; then
    BACKUP=$(ls -t "$ITER_DIR"/backup_pre_deploy_*.tgz 2>/dev/null | head -1 || echo "")
    if [ -z "$BACKUP" ]; then
        echo "WARNING: no backup found in $ITER_DIR — current/ NOT restored. Verdict recorded only."
    else
        echo "Restoring current/metadata/ from $BACKUP ..."
        rm -rf current/metadata
        tar -xzf "$BACKUP" -C current
        echo "  → current/metadata/ restored"
        echo "  → remember to run 'fastlane sync_metadata' to push the rollback"
    fi
fi

CLOSE_TS=$(date +%Y-%m-%d)

# Update meta.json
python3 -c "
import json
with open('$ITER_DIR/meta.json') as f: m = json.load(f)
m['status'] = 'closed'
m['actual_closed_at'] = '$CLOSE_TS'
m['verdict'] = '$VERDICT'
m['promoted_to_current'] = ('$VERDICT' == 'won')
with open('$ITER_DIR/meta.json','w') as f: json.dump(m, f, indent=2, ensure_ascii=False)
print('Updated meta.json: status=closed, verdict=$VERDICT')
"

# Append to registry/winners.json
python3 -c "
import json
with open('$ITER_DIR/meta.json') as f: m = json.load(f)
with open('registry/winners.json') as f: w = json.load(f)
w.setdefault('history',[]).append({
    'iter_id': m['iter_id'],
    'closed_at': '$CLOSE_TS',
    'type': m.get('type'),
    'locale': m.get('locale'),
    'field': m.get('field'),
    'verdict': '$VERDICT',
    'hypothesis': m.get('hypothesis',{}),
    'success_criterion': m.get('success_criterion',{}),
    'promoted_to_current': ('$VERDICT' == 'won'),
    'notes': m.get('notes','')
})
with open('registry/winners.json','w') as f: json.dump(w, f, indent=2, ensure_ascii=False)
print('Appended to registry/winners.json')
"

echo ""
echo "Iteration closed."
echo "  Iter:    $ITER_DIR"
echo "  Verdict: $VERDICT"
echo ""
echo "Next:"
echo "  - Update registry/keywords_tested.json with what worked/lost (manual)"
echo "  - Update registry/ideation_backlog.json with new hypotheses learned"
echo "  - Update reports/progress.md with this iter's lessons"
echo "  - Commit everything"
echo "  - Start next iter: ./scripts/new_iteration.sh ..."
