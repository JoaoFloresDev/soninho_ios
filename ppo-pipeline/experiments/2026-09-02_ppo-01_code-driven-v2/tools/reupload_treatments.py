#!/usr/bin/env python3
"""Replace every screenshot in the existing PPO treatment sets with the
freshly rendered files (v2: per-treatment order/layout). Idempotent: a shot
whose sourceFileChecksum already matches a local file is kept, everything
else is deleted; missing files are uploaded; final order = sorted filenames.
"""
import sys, hashlib, time
from pathlib import Path
import urllib.request as ur

sys.path.insert(0, "/private/tmp/claude-501/-Users-joaoflores-Documents-GambitStudio/37c42cfd-8e58-4c78-ae8f-7a8f2d6deb80/scratchpad")
from asc import req

TREATMENTS = {"A": "88dd6224-c8dc-4933-a544-23b7888222d3",
              "B": "266b91d7-8364-4a1d-93ea-049f0ff554d6",
              "C": "79947143-224e-46bb-a674-29beff33bfa0"}
BASE = Path(__file__).resolve().parents[4] / "fastlane" / "screenshots"


def upload_png(set_id: str, png: Path) -> str:
    data = png.read_bytes()
    md5 = hashlib.md5(data).hexdigest()
    res, _ = req("POST", "/v1/appScreenshots", {
        "data": {"type": "appScreenshots",
                 "attributes": {"fileName": png.name, "fileSize": len(data)},
                 "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})
    if "ERROR" in res:
        raise RuntimeError(f"reserve failed for {png.name}: {res}")
    sid = res["data"]["id"]
    op = res["data"]["attributes"]["uploadOperations"][0]
    rq = ur.Request(op["url"], data=data, method=op["method"],
                    headers={h["name"]: h["value"] for h in op["requestHeaders"]})
    ur.urlopen(rq)
    req("PATCH", f"/v1/appScreenshots/{sid}", {
        "data": {"type": "appScreenshots", "id": sid,
                 "attributes": {"uploaded": True, "sourceFileChecksum": md5}}})
    return sid


def main() -> int:
    for letter, tid in TREATMENTS.items():
        locs, _ = req("GET", f"/v1/appStoreVersionExperimentTreatments/{tid}/appStoreVersionExperimentTreatmentLocalizations")
        for loc in locs["data"]:
            lc = loc["attributes"]["locale"]
            local = {p.name: hashlib.md5(p.read_bytes()).hexdigest()
                     for p in sorted((BASE / f"treatment_{letter}" / lc).glob("*.png"))}
            sets, _ = req("GET", f"/v1/appStoreVersionExperimentTreatmentLocalizations/{loc['id']}/appScreenshotSets?include=appScreenshots")
            st = sets["data"][0]
            shots = {i["id"]: i for i in sets.get("included", [])}
            keep: dict[str, str] = {}
            for r in st["relationships"]["appScreenshots"]["data"]:
                a = shots[r["id"]]["attributes"]
                if local.get(a["fileName"]) == a.get("sourceFileChecksum") and a["fileName"] not in keep:
                    keep[a["fileName"]] = r["id"]
                else:
                    req("DELETE", f"/v1/appScreenshots/{r['id']}")
            for name in local:
                if name not in keep:
                    keep[name] = upload_png(st["id"], BASE / f"treatment_{letter}" / lc / name)
            ordered = [keep[name] for name in sorted(keep)]
            req("PATCH", f"/v1/appScreenshotSets/{st['id']}/relationships/appScreenshots",
                {"data": [{"type": "appScreenshots", "id": i} for i in ordered]})
            print(f"{letter}/{lc}: {len(ordered)} shots reconciled ({len(local) - 5 + 5} local)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
