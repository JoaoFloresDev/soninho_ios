#!/usr/bin/env python3
"""Submit the PPO experiment for review via the ASC API (LEARNINGS #39).

Usage: python3 submit_review.py <experiment_id>

Flow: POST /v1/reviewSubmissions (IOS + app) -> POST /v1/reviewSubmissionItems
with relationship appStoreVersionExperiment -> PATCH submitted:true.
Start (PATCH started:true) happens ONLY after approval, preceded by a
checksum re-verify of every treatment set (LEARNINGS #35).
"""
import sys, time

sys.path.insert(0, "/private/tmp/claude-501/-Users-joaoflores-Documents-GambitStudio/37c42cfd-8e58-4c78-ae8f-7a8f2d6deb80/scratchpad")
from asc import req

APP_ID = "6758740138"

def main() -> int:
    exp_id = sys.argv[1]
    sub, _ = req("POST", "/v1/reviewSubmissions", {
        "data": {"type": "reviewSubmissions",
                 "attributes": {"platform": "IOS"},
                 "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}}}})
    if "ERROR" in sub:
        print("reviewSubmission failed:", sub); return 1
    sub_id = sub["data"]["id"]
    print("reviewSubmission:", sub_id)

    for attempt in range(3):
        item, _ = req("POST", "/v1/reviewSubmissionItems", {
            "data": {"type": "reviewSubmissionItems",
                     "relationships": {
                         "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
                         "appStoreVersionExperiment": {"data": {"type": "appStoreVersionExperiments", "id": exp_id}}}}})
        if "ERROR" not in item:
            print("item:", item["data"]["id"]); break
        print(f"item attempt {attempt+1} failed:", item.get("body", item))
        time.sleep(5)  # 500 transiente acontece (LEARNINGS #57b)
    else:
        return 1

    done, _ = req("PATCH", f"/v1/reviewSubmissions/{sub_id}", {
        "data": {"type": "reviewSubmissions", "id": sub_id,
                 "attributes": {"submitted": True}}})
    if "ERROR" in done:
        print("submit failed:", done); return 1
    print("state:", done["data"]["attributes"].get("state"))
    print("submission_id:", sub_id)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
