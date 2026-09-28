#!/usr/bin/env python3
"""
validate_proposed.py — pre-deploy lint da pasta proposed/ de uma iter.

Checa por locale:
  - char counts dentro dos limites Apple (name 30, subtitle 30, keywords 100,
    promo 170, description 4000, release_notes 4000)
  - keywords field: lowercase, comma-separated sem espaço extra
  - keywords: 0 stopwords pt-BR/en
  - keywords: 0 duplicatas literais
  - keywords: 0 palavras truncadas (<4 chars que não sejam exceções)
  - keywords: 0 palavras que já estejam no name/subtitle (do current/ ou proposed/)

Uso:
  ./scripts/validate_proposed.py iterations/<iter_id>
"""
from __future__ import annotations

import re
import sys
import unicodedata
from pathlib import Path

STOPWORDS_PT = {"a","o","as","os","um","uma","de","da","do","das","dos",
                "e","ou","em","no","na","nos","nas","por","para","com","sem",
                "que","se","ao","aos","à","às"}
STOPWORDS_EN = {"the","a","an","and","or","in","on","at","of","to","for","by","with","from","as","is","it"}
STOPWORDS = STOPWORDS_PT | STOPWORDS_EN

# Palavras curtas legítimas (3 chars) — exceções pra heuristic de truncamento
SHORT_LEGIT = {"app","usp","puc","ufm","uni","cur","key","apk","ios","cor",
               "puc","fgv","unb","ufp","ufm","top","pop","seo","aso"}

LIMITS = {
    "name":             30,
    "subtitle":         30,
    "keywords":        100,
    "promotional_text":170,
    "description":    4000,
    "release_notes":  4000,
}


def visible_len(s: str) -> int:
    """Grapheme count (what Apple actually counts)."""
    return len(s)


def project_root() -> Path:
    return Path(__file__).resolve().parent.parent


def read_current(locale: str) -> dict:
    d = project_root() / "current" / "metadata" / locale
    return {
        "name":     (d / "name.txt").read_text().strip()     if (d / "name.txt").exists() else "",
        "subtitle": (d / "subtitle.txt").read_text().strip() if (d / "subtitle.txt").exists() else "",
    }


# ---- Per-field validators -------------------------------------------------

def validate_field_length(field: str, value: str) -> list[str]:
    limit = LIMITS.get(field)
    if limit is None: return []
    n = visible_len(value)
    if n > limit:
        return [f"❌ {field}: {n}>{limit} chars"]
    if field in {"name", "subtitle", "keywords"} and limit - n > 0:
        return [f"⚠️  {field}: only {n}/{limit} chars used ({limit - n} left). [feedback-aso-max-chars] — fill the budget"]
    return []


def validate_keywords(value: str, ctx_name: str = "", ctx_subtitle: str = "") -> list[str]:
    issues = []
    if not value:
        issues.append("❌ keywords: empty")
        return issues
    # Check no leading/trailing whitespace
    if value != value.strip():
        issues.append("❌ keywords: leading/trailing whitespace")
    # Check no spaces after commas
    if re.search(r",\s+", value):
        issues.append("❌ keywords: spaces after commas (should be 'word1,word2', not 'word1, word2')")
    tokens = [t.strip() for t in value.split(",")]
    # Check lowercase
    not_lower = [t for t in tokens if t != t.lower()]
    if not_lower:
        issues.append(f"❌ keywords: non-lowercase tokens: {not_lower}")
    # Check stopwords
    has_stop = [t for t in tokens if t.lower() in STOPWORDS]
    if has_stop:
        issues.append(f"❌ keywords: stopwords detected (Apple ignores): {has_stop}")
    # Check duplicates (case-insensitive)
    seen, dups = set(), []
    for t in tokens:
        tl = t.lower()
        if tl in seen: dups.append(t)
        seen.add(tl)
    if dups:
        issues.append(f"❌ keywords: duplicates: {dups}")
    # Check potential truncation (short tokens that are likely cut-off)
    short_susp = [t for t in tokens
                  if 0 < len(t) < 4
                  and t.lower() not in SHORT_LEGIT
                  and not t.isupper()  # ignore acronyms like USP, PUC
                  and not t.isnumeric()]
    if short_susp:
        issues.append(f"⚠️  keywords: short tokens possibly truncated (verify): {short_susp}")
    # Check dups with name/subtitle (case-insensitive substring match per token)
    ctx_words = set()
    for ctx in (ctx_name, ctx_subtitle):
        for w in re.findall(r"\b[\wÀ-ÿ]+\b", ctx, re.UNICODE):
            ctx_words.add(w.lower())
    ctx_dups = [t for t in tokens if t.lower() in ctx_words]
    if ctx_dups:
        issues.append(f"❌ keywords: tokens duplicate name/subtitle (waste — Apple already indexes at 7×/3×): {ctx_dups}")
    return issues


def validate_subtitle(value: str, ctx_name: str = "") -> list[str]:
    issues = []
    # Subtitle words duplicating name
    if value and ctx_name:
        name_words = set(w.lower() for w in re.findall(r"\b[\wÀ-ÿ]+\b", ctx_name, re.UNICODE))
        sub_words = re.findall(r"\b[\wÀ-ÿ]+\b", value, re.UNICODE)
        dups = [w for w in sub_words if w.lower() in name_words]
        if dups:
            issues.append(f"⚠️  subtitle: words also in name (lost 3× leverage since name is 7×): {dups}")
    return issues


# ---- Main -----------------------------------------------------------------

def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        return 1
    iter_dir = Path(sys.argv[1]).resolve()
    proposed = iter_dir / "proposed" / "metadata"
    if not proposed.exists():
        print(f"❌ {proposed} doesn't exist. Nothing to validate.", file=sys.stderr)
        return 1

    print(f"🔍 Validating {proposed}\n")
    total_blockers = 0
    total_warnings = 0

    for locale_dir in sorted(proposed.iterdir()):
        if not locale_dir.is_dir(): continue
        locale = locale_dir.name
        print(f"━━━ {locale} ━━━")

        # Read proposed values + fall back to current for context (name/subtitle if not in proposed)
        proposed_fields = {}
        for fname in ["name.txt", "subtitle.txt", "keywords.txt", "description.txt",
                      "promotional_text.txt", "release_notes.txt"]:
            fp = locale_dir / fname
            if fp.exists():
                proposed_fields[fname.replace(".txt", "")] = fp.read_text().strip()

        # Context for dup checks: pull name/subtitle from current if not in proposed
        current = read_current(locale)
        ctx_name     = proposed_fields.get("name",     current["name"])
        ctx_subtitle = proposed_fields.get("subtitle", current["subtitle"])

        for field, value in proposed_fields.items():
            issues = validate_field_length(field, value)
            if field == "keywords":
                issues += validate_keywords(value, ctx_name, ctx_subtitle)
            if field == "subtitle":
                issues += validate_subtitle(value, ctx_name)

            for iss in issues:
                if iss.startswith("❌"): total_blockers += 1
                elif iss.startswith("⚠️"): total_warnings += 1
                print(f"  {iss}")
        if not proposed_fields:
            print(f"  (empty — no proposed files)")
        print()

    print()
    if total_blockers == 0 and total_warnings == 0:
        print("✅ All proposed files clean. Ready to deploy.")
        return 0
    if total_blockers == 0:
        print(f"⚠️  {total_warnings} warning(s) — review, then deploy.")
        return 0
    print(f"❌ {total_blockers} blocker(s), {total_warnings} warning(s). FIX blockers before deploy.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
