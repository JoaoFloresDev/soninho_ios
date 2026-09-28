#!/usr/bin/env python3
"""
verify_current.py — checks that aso-pipeline/current/metadata/ matches the
LIVE state on App Store Connect for the live (READY_FOR_SALE) version.

Exit code 0 = all in sync, 1 = at least one divergence.

Loads APP_ID + auth from env vars or defaults to GambitStudio standard.
"""
from __future__ import annotations

import json
import os
import sys
import time
import urllib.request
from pathlib import Path

import jwt

KEY_ID    = os.getenv("APP_STORE_CONNECT_KEY_ID",    "67JG58Q6XH")
ISSUER_ID = os.getenv("APP_STORE_CONNECT_ISSUER_ID", "98c49316-b223-4d64-955d-b55ae76ab9d2")
KEY_PATH  = os.path.expanduser(os.getenv("APP_STORE_CONNECT_KEY_PATH", "~/Documents/GambitStudio/_GambitStudio/keys/asc_api_key.p8"))
APP_ID    = os.getenv("APP_ID", "6758740138")

CURRENT_META = Path(__file__).resolve().parent.parent / "current" / "metadata"

STRICT_MODE = "--strict" in sys.argv


def make_token() -> str:
    pk = open(KEY_PATH).read()
    n = int(time.time())
    return jwt.encode({"iss": ISSUER_ID, "iat": n, "exp": n + 1200, "aud": "appstoreconnect-v1"},
                      pk, algorithm="ES256", headers={"kid": KEY_ID, "typ": "JWT"})


def api(path: str) -> dict:
    req = urllib.request.Request(f"https://api.appstoreconnect.apple.com{path}",
                                 headers={"Authorization": f"Bearer {make_token()}",
                                          "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())


def fetch_live_state() -> dict:
    """Returns: {locale: {name, subtitle, keywords, description, promotionalText, releaseNotes}}"""
    # Find LIVE (READY_FOR_SALE) version
    versions = api(f"/v1/apps/{APP_ID}/appStoreVersions?limit=20")
    live_v = next((v for v in versions["data"] if v["attributes"]["appStoreState"] == "READY_FOR_SALE"), None)
    if not live_v:
        sys.exit("❌ No live (READY_FOR_SALE) version found on ASC.")

    # Find LIVE AppInfo
    app_infos = api(f"/v1/apps/{APP_ID}/appInfos")
    live_ai = next((ai for ai in app_infos["data"] if ai["attributes"]["appStoreState"] == "READY_FOR_SALE"), None)

    ai_locs = api(f"/v1/appInfos/{live_ai['id']}/appInfoLocalizations?limit=50")
    ai_by_locale = {l["attributes"]["locale"]: l["attributes"] for l in ai_locs["data"]}

    ver_locs = api(f"/v1/appStoreVersions/{live_v['id']}/appStoreVersionLocalizations?limit=50")
    ver_by_locale = {l["attributes"]["locale"]: l["attributes"] for l in ver_locs["data"]}

    out = {}
    all_locales = set(ai_by_locale) | set(ver_by_locale)
    for loc in all_locales:
        ai = ai_by_locale.get(loc, {})
        ver = ver_by_locale.get(loc, {})
        out[loc] = {
            "name":             ai.get("name") or "",
            "subtitle":         ai.get("subtitle") or "",
            "keywords":         ver.get("keywords") or "",
            "description":      ver.get("description") or "",
            "promotional_text": ver.get("promotionalText") or "",
            "release_notes":    ver.get("whatsNew") or "",
        }
    return out


def read_local(locale: str) -> dict:
    d = CURRENT_META / locale
    return {
        "name":             (d / "name.txt").read_text().strip()             if (d / "name.txt").exists() else "",
        "subtitle":         (d / "subtitle.txt").read_text().strip()         if (d / "subtitle.txt").exists() else "",
        "keywords":         (d / "keywords.txt").read_text().strip()         if (d / "keywords.txt").exists() else "",
        "description":      (d / "description.txt").read_text().strip()      if (d / "description.txt").exists() else "",
        "promotional_text": (d / "promotional_text.txt").read_text().strip() if (d / "promotional_text.txt").exists() else "",
        "release_notes":    (d / "release_notes.txt").read_text().strip()    if (d / "release_notes.txt").exists() else "",
    }


def short(s: str, n: int = 50) -> str:
    return (s[:n] + "…") if len(s) > n else s


def main() -> int:
    live = fetch_live_state()
    local_locales = sorted({d.name for d in CURRENT_META.iterdir() if d.is_dir()})

    print(f"🔎 Verifying current/metadata/ against ASC live state…\n")

    total_diffs = 0
    all_fields = ["name", "subtitle", "keywords", "description", "promotional_text", "release_notes"]

    for loc in local_locales:
        if loc not in live:
            print(f"⚠️  {loc}: NOT on live ASC (folder exists locally but no live data)")
            print(f"     → either this locale is staged for next version, or folder should be deleted\n")
            continue

        local = read_local(loc)
        live_loc = live[loc]
        diffs = [f for f in all_fields if local.get(f, "").strip() != live_loc.get(f, "").strip()]
        if not diffs:
            print(f"✅ {loc}: in sync")
            continue

        total_diffs += len(diffs)
        print(f"❌ {loc}: {len(diffs)} divergence(s)")
        for f in diffs:
            print(f"     {f}:")
            print(f"       local:  {short(local.get(f, ''))!r}")
            print(f"       live:   {short(live_loc.get(f, ''))!r}")
        print()

    # Locales on live but missing locally
    for loc in sorted(set(live) - set(local_locales)):
        print(f"⚠️  {loc}: live on ASC but NO folder in current/metadata/")
        print(f"     → create folder + files via verify_current --pull or sync_current_from_asc.py\n")
        total_diffs += 1

    print()
    if total_diffs == 0:
        print("✅ current/metadata/ matches ASC live state. 0 divergences.")
        return 0
    print(f"❌ Found {total_diffs} divergence(s).")
    if STRICT_MODE:
        return 1
    print("   (run with --strict to exit 1 in CI mode)")
    return 1


if __name__ == "__main__":
    sys.exit(main())
