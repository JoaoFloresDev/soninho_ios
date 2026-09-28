#!/usr/bin/env python3
"""
astro_mcp.py — Lightweight Astro MCP HTTP client for the ASO pipeline.

Astro Desktop expõe um MCP server em http://127.0.0.1:8089/mcp. Este script
encapsula as chamadas mais usadas: list_apps, add_app, add_keywords (com batch
auto-split de 100), get_app_keywords, merge JSON pull → CSV columns.

Uso típico no flow do skill start-aso-pipeline:

  ./scripts/astro_mcp.py list                                      # ver apps tracked
  ./scripts/astro_mcp.py add-app <APP_ID> iphone                 # bootstrap app novo
  ./scripts/astro_mcp.py add <APP_ID> us --from-file /tmp/kw.txt # push keywords
  ./scripts/astro_mcp.py pull <APP_ID> us > /tmp/us.json         # pull rankings
  ./scripts/astro_mcp.py merge --astro /tmp/us.json \
      iterations/<iter>/research/current_pool_us.csv \
      iterations/<iter>/research/candidates_us.csv                  # merge data → CSV cols

Override URL via env: ASTRO_MCP_URL=http://other.host:8089/mcp ./scripts/astro_mcp.py ...
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import sys
import urllib.request
from typing import Any

MCP_URL = os.environ.get("ASTRO_MCP_URL", "http://127.0.0.1:8089/mcp")

_session_id: str | None = None
_req_id = 0


def _next_id() -> int:
    global _req_id
    _req_id += 1
    return _req_id


def _post(payload: dict, expect_session: bool = False) -> tuple[str | None, str]:
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json, text/event-stream",
    }
    if _session_id:
        headers["Mcp-Session-Id"] = _session_id
    req = urllib.request.Request(MCP_URL, data=json.dumps(payload).encode(), headers=headers)
    resp = urllib.request.urlopen(req, timeout=300)
    sid = resp.headers.get("Mcp-Session-Id") if expect_session else None
    body = resp.read().decode()
    return sid, body


def _init() -> None:
    global _session_id
    sid, _body = _post(
        {
            "jsonrpc": "2.0",
            "id": _next_id(),
            "method": "initialize",
            "params": {
                "protocolVersion": "2025-03-26",
                "capabilities": {},
                "clientInfo": {"name": "aso-pipeline-cli", "version": "1.0"},
            },
        },
        expect_session=True,
    )
    _session_id = sid
    _post({"jsonrpc": "2.0", "method": "notifications/initialized"})


def call(tool: str, args: dict) -> tuple[Any, dict | None]:
    """Call an MCP tool. Returns (parsed_payload, error_or_None)."""
    if _session_id is None:
        _init()
    _, body = _post(
        {
            "jsonrpc": "2.0",
            "id": _next_id(),
            "method": "tools/call",
            "params": {"name": tool, "arguments": args},
        }
    )
    d = json.loads(body)
    if "error" in d:
        return None, d["error"]
    for c in d.get("result", {}).get("content", []):
        if c.get("type") == "text":
            try:
                return json.loads(c["text"]), None
            except json.JSONDecodeError:
                return c["text"], None
    return None, None


# ---------- subcommands ----------

def cmd_list(_args) -> None:
    data, err = call("list_apps", {})
    if err:
        sys.exit(f"err: {err}")
    if isinstance(data, list):
        for a in data:
            print(
                f"[{a.get('appId', '?'):>12}] "
                f"{(a.get('name') or '?')[:45]:<45} "
                f"kw={a.get('keywordCount', 0):>4} "
                f"stores={a.get('stores', [])}"
            )
    else:
        print(json.dumps(data, indent=2))


def cmd_add_app(args) -> None:
    data, err = call("add_app", {"appStoreId": args.appId, "platform": args.platform})
    if err:
        sys.exit(f"err: {err}")
    print(json.dumps(data, indent=2))


def cmd_add(args) -> None:
    """Batch add keywords. Reads from --from-file (one per line) or positional list."""
    if args.from_file:
        kws = [l.strip() for l in open(args.from_file) if l.strip()]
    else:
        kws = args.keywords
    if not kws:
        sys.exit("no keywords")
    # MCP limit: 100 per call
    added_total = 0
    skipped_total = 0
    for i in range(0, len(kws), 100):
        batch = kws[i : i + 100]
        print(f"Batch {i // 100 + 1}: {len(batch)} keywords...", file=sys.stderr)
        data, err = call(
            "add_keywords",
            {
                "appId": args.appId,
                "keywords": batch,
                "store": args.store,
                "platform": args.platform,
            },
        )
        if err:
            sys.exit(f"err on batch {i // 100 + 1}: {err}")
        added = data.get("added", 0) if isinstance(data, dict) else 0
        # count skipped
        sk = sum(
            1
            for r in (data.get("results", []) if isinstance(data, dict) else [])
            if r.get("skipped")
        )
        added_total += added
        skipped_total += sk
        print(f"  added={added} skipped={sk}", file=sys.stderr)
    print(
        f"Total: added={added_total} skipped={skipped_total} / {len(kws)} keywords",
        file=sys.stderr,
    )


def cmd_pull(args) -> None:
    """Pull all tracked keywords for an app+store. Writes JSON to stdout."""
    data, err = call("get_app_keywords", {"appId": args.appId, "store": args.store})
    if err:
        sys.exit(f"err: {err}")
    print(json.dumps(data, indent=2))


def cmd_merge(args) -> None:
    """Merge an Astro JSON pull into one or more CSV files in-place."""
    astro = json.load(open(args.astro))
    if not isinstance(astro, list):
        sys.exit(f"expected list in {args.astro}, got {type(astro).__name__}")
    by_kw = {k["keyword"].strip().lower(): k for k in astro}
    for csv_path in args.csvs:
        with open(csv_path) as fh:
            rows = list(csv.DictReader(fh))
        if not rows:
            print(f"skip empty: {csv_path}", file=sys.stderr)
            continue
        hits = 0
        for r in rows:
            kw = r.get("Keyword", "").strip().lower()
            a = by_kw.get(kw)
            if not a:
                continue
            hits += 1
            r["Ranking"] = str(a["currentRanking"]) if a["currentRanking"] < 1000 else "OUT"
            r["Change"] = str(a.get("rankingChange", 0))
            r["Popularity"] = str(a["popularity"])
            r["Difficulty"] = str(a["difficulty"])
            r["Apps in Ranking"] = str(a["appsCount"])
            r["Last Update"] = a.get("lastUpdate", "")[:10]
        fields = list(rows[0].keys())
        with open(csv_path, "w", newline="") as fh:
            w = csv.DictWriter(fh, fieldnames=fields)
            w.writeheader()
            w.writerows(rows)
        print(f"{csv_path}: {hits}/{len(rows)} merged", file=sys.stderr)


def cmd_search(args) -> None:
    """Search rankings for a single keyword (debug helper)."""
    data, err = call(
        "search_rankings",
        {
            "keyword": args.keyword,
            "store": args.store,
            "includeHistory": args.history,
            "includeStatistics": args.history,
        },
    )
    if err:
        sys.exit(f"err: {err}")
    print(json.dumps(data, indent=2))


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("list", help="list tracked apps").set_defaults(func=cmd_list)

    pa = sub.add_parser("add-app", help="add a new app to tracking")
    pa.add_argument("appId")
    pa.add_argument("platform", nargs="?", default="iphone")
    pa.set_defaults(func=cmd_add_app)

    pad = sub.add_parser("add", help="add keywords to an app")
    pad.add_argument("appId")
    pad.add_argument("store")
    pad.add_argument("keywords", nargs="*")
    pad.add_argument("--from-file", help="read keywords from file (one per line)")
    pad.add_argument("--platform", default="iphone")
    pad.set_defaults(func=cmd_add)

    pp = sub.add_parser("pull", help="pull all keywords for app+store as JSON")
    pp.add_argument("appId")
    pp.add_argument("store")
    pp.set_defaults(func=cmd_pull)

    pm = sub.add_parser("merge", help="merge Astro JSON into CSV files")
    pm.add_argument("--astro", required=True, help="path to JSON from `pull` cmd")
    pm.add_argument("csvs", nargs="+", help="CSV files to update in-place")
    pm.set_defaults(func=cmd_merge)

    ps = sub.add_parser("search", help="lookup single keyword (debug)")
    ps.add_argument("keyword")
    ps.add_argument("store")
    ps.add_argument("--history", action="store_true")
    ps.set_defaults(func=cmd_search)

    args = p.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
