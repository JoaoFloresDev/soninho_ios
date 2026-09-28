#!/usr/bin/env python3
"""
sync_current_from_asc.py — pulls the LIVE (READY_FOR_SALE) state from App Store
Connect and writes it into aso-pipeline/current/metadata/<locale>/<field>.txt.

Use this whenever current/metadata/ has drifted from ASC, or to bootstrap a
brand-new pipeline.
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

FIELD_FILE_MAP = {
    "name":             "name.txt",
    "subtitle":         "subtitle.txt",
    "keywords":         "keywords.txt",
    "description":      "description.txt",
    "promotional_text": "promotional_text.txt",
    "release_notes":    "release_notes.txt",
}


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
    versions = api(f"/v1/apps/{APP_ID}/appStoreVersions?limit=20")
    live_v = next((v for v in versions["data"] if v["attributes"]["appStoreState"] == "READY_FOR_SALE"), None)
    if not live_v:
        sys.exit("❌ No live (READY_FOR_SALE) version found on ASC.")

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


def main() -> int:
    live = fetch_live_state()
    CURRENT_META.mkdir(parents=True, exist_ok=True)
    print(f"📥 Syncing {len(live)} locales from ASC live state\n")

    for loc, fields in sorted(live.items()):
        d = CURRENT_META / loc
        d.mkdir(parents=True, exist_ok=True)
        for field, fname in FIELD_FILE_MAP.items():
            value = fields.get(field) or ""
            (d / fname).write_text(value + ("\n" if value and not value.endswith("\n") else ""))
        print(f"  ✅ {loc}: {len(fields)} files written")

    print(f"\n✅ Done. current/metadata/ now mirrors ASC live state.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
