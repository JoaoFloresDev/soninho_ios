#!/usr/bin/env bash
# new_iteration.sh — scaffold a new iteration folder.
#
# Usage:
#   ./scripts/new_iteration.sh text pt-BR keywords
#   ./scripts/new_iteration.sh text pt-BR subtitle
#   ./scripts/new_iteration.sh text pt-BR name
#   ./scripts/new_iteration.sh description pt-BR
#   ./scripts/new_iteration.sh ppo               # PPO test (whole-period)
#
# Creates:
#   iterations/<YYYY-MM-DD>_iter-<NN>-<type>-<locale>[-<field>]/
#     meta.json              filled with template (hypothesis TODO)
#     proposed/              empty — fill with the diff vs current
#     research/              empty — fill with astro_export.csv, competitors.md, keyword_candidates.md
#     metrics/               empty — pull_analytics.py outputs go here

set -euo pipefail

cd "$(dirname "$0")/.."

TYPE=${1:?Usage: $0 <text|description|ppo> [<locale>] [<field>]}
LOCALE=${2:-all}
FIELD=${3:-}

DATE=$(date +%Y-%m-%d)

# Find next iter number
LAST_NUM=$(ls -d iterations/*_iter-*/ 2>/dev/null | sed -E 's|iterations/[0-9-]+_iter-([0-9]+).*|\1|' | sort -n | tail -1 || echo "0")
if [ -z "$LAST_NUM" ]; then LAST_NUM=0; fi
NEXT_NUM=$(printf "%02d" $((10#$LAST_NUM + 1)))

# Build folder name
SLUG="${TYPE}"
if [ "$LOCALE" != "all" ]; then SLUG="${SLUG}-${LOCALE}"; fi
if [ -n "$FIELD" ]; then SLUG="${SLUG}-${FIELD}"; fi
ITER_DIR="iterations/${DATE}_iter-${NEXT_NUM}-${SLUG}"

mkdir -p "$ITER_DIR"/{proposed,research,metrics}

# Compute end date 4 weeks from now (macOS date syntax)
END_DATE=$(date -v+28d +%Y-%m-%d 2>/dev/null || date -d "+28 days" +%Y-%m-%d)

# meta.json template
cat > "$ITER_DIR/meta.json" <<EOF
{
  "iter_id": "${DATE}_iter-${NEXT_NUM}-${SLUG}",
  "type": "${TYPE}",
  "locale": "${LOCALE}",
  "field": "${FIELD}",
  "status": "draft",
  "started_at": "${DATE}",
  "planned_close_at": "${END_DATE}",
  "actual_closed_at": null,

  "hypothesis": {
    "if_we_change": "TODO — what specifically? e.g. 'replace lowest-popularity 30% of keywords with Astro top candidates'",
    "then_we_expect": "TODO — measurable outcome. e.g. 'impressions +25% in 30d'",
    "because": "TODO — why? e.g. 'Astro popularity score correlates with daily search volume; current keywords have score <20'"
  },

  "success_criterion": {
    "metric": "TODO — impressions | downloads | search_term_count | CVR | rank",
    "threshold": "TODO — number to beat. e.g. '17 downloads/day average over last 14d of iter'",
    "compared_to": "baseline at start of iter"
  },

  "research_done": false,
  "deployed": false,
  "deploy_commit": null,

  "results": {
    "baseline": {"date": "${DATE}", "metrics_file": "metrics/${DATE}_baseline.csv"},
    "checkpoints": [],
    "final": null
  },

  "verdict": null,
  "promoted_to_current": false,
  "notes": ""
}
EOF

# Seed the proposed/ folder structure
if [ "$TYPE" = "text" ] && [ "$LOCALE" != "all" ]; then
    mkdir -p "$ITER_DIR/proposed/metadata/${LOCALE}"
fi

if [ "$TYPE" = "ppo" ]; then
    mkdir -p "$ITER_DIR/proposed/screenshots/treatment_A" "$ITER_DIR/proposed/screenshots/treatment_B"
fi

# Pre-fill research/ with empty templates
cat > "$ITER_DIR/research/competitors.md" <<'EOF'
# Competitor research

Top 3 competitor apps in same niche (App Store):

## 1. <competitor app name>
- Bundle ID:
- Visible keywords (name + subtitle):
- Notes:

## 2. <competitor app name>
- Bundle ID:
- Visible keywords (name + subtitle):
- Notes:

## 3. <competitor app name>
- Bundle ID:
- Visible keywords (name + subtitle):
- Notes:

## Insights

What keywords do competitors use that we don't?
What positioning do they take?
What seems to work for them (rank-wise)?
EOF

cat > "$ITER_DIR/research/keyword_candidates.md" <<'EOF'
# Keyword shortlist

Source: Astro (popularity ≥ 30, difficulty ≤ 50)
See `astro_export.csv` for raw data.

| keyword | astro popularity | astro difficulty | current rank | priority |
|---------|------------------|------------------|--------------|----------|
| TODO    | -                | -                | -            | -        |

## Decision: keywords to ADD this iter

1.
2.
3.

## Decision: keywords to REMOVE this iter (and why)

1.  -
2.  -
3.  -

## Char count of proposed keywords.txt: TODO/100
EOF

echo "Created: $ITER_DIR"
echo ""
echo "Next steps:"
echo "  1. Fill research/ — competitors.md, astro_export.csv, keyword_candidates.md"
echo "  2. Edit meta.json — write your hypothesis (If X, then Y, because Z)"
echo "  3. Edit proposed/metadata/${LOCALE}/<field>.txt — the actual change"
echo "  4. Run baseline: ./scripts/pull_analytics.py $ITER_DIR"
echo "  5. Deploy:       ./scripts/deploy.sh $ITER_DIR"
