#!/usr/bin/env python3
"""Post inline (and top-level) review comments to a Bitbucket Cloud pull request.

The PR-review *reasoning* is forge-agnostic and lives in the review-pr skill.
This script is only the Bitbucket-specific mechanics of anchoring findings to
lines and POSTing them, since Bitbucket's API differs from GitHub's:

  - GitHub anchors inline comments by ``position`` (offset within a diff hunk).
  - Bitbucket anchors by ``inline.path`` + ``inline.to`` -- the ACTUAL line
    number in the destination (new) version of the file. Simpler: no hunk math.

Auth (Bitbucket Cloud, Basic auth with an Atlassian API token):
    export BITBUCKET_API_TOKEN=...            # required
    export BITBUCKET_EMAIL=you@example.com    # or pass --email

Input: JSON, either a bare list or ``{"comments": [...]}``. Each comment is:
    {"path": "src/foo.py", "line": 168, "body": "**high** -- ..."}   # inline
    {"body": "General note about the PR."}                          # top-level
``line`` is the new-file line number (maps to Bitbucket ``inline.to``); use
``"side": "from"`` to anchor a deleted line instead. ``path`` without ``line``
anchors to the top of the file's diff.

Usage:
    python bb_post_inline_comments.py --repo acme/widgets --pr 42 --file review.json
    cat review.json | python bb_post_inline_comments.py -R acme/widgets --pr 42
    python bb_post_inline_comments.py -R acme/widgets --pr 42 --file review.json --dry-run

Exit codes: 0 all posted (or dry-run), 1 one or more failed, 2 bad usage/auth/input.
"""

import argparse
import base64
import json
import os
import sys
import urllib.error
import urllib.request

API_ROOT = "https://api.bitbucket.org/2.0"


def _auth_header(email: str, token: str) -> str:
    return "Basic " + base64.b64encode(f"{email}:{token}".encode()).decode()


def _build_payload(comment: dict) -> dict:
    """Map a finding dict -> the Bitbucket comment request body."""
    body = comment.get("body")
    if not body:
        raise ValueError("comment is missing a non-empty 'body'")
    payload: dict = {"content": {"raw": body}}
    path = comment.get("path")
    if path:
        inline = {"path": path}
        line = comment.get("line")
        if line is not None:
            # "from" anchors a removed line; default "to" anchors the new-file line.
            key = "from" if comment.get("side") == "from" else "to"
            inline[key] = int(line)
        payload["inline"] = inline
    return payload


def _load_comments(source: str) -> list:
    raw = sys.stdin.read() if source == "-" else open(source, encoding="utf-8").read()
    data = json.loads(raw)
    if isinstance(data, dict):
        data = data.get("comments", [])
    if not isinstance(data, list):
        raise ValueError("input must be a JSON list or an object with a 'comments' list")
    return data


def _post(url: str, payload: dict, auth: str) -> dict:
    req = urllib.request.Request(
        url, data=json.dumps(payload).encode(), method="POST",
        headers={"Authorization": auth, "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req) as resp:
        return json.load(resp)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-R", "--repo", required=True, help="WORKSPACE/REPO, e.g. acme/widgets")
    ap.add_argument("--pr", required=True, type=int, help="Pull request number")
    ap.add_argument("--file", default="-", help="JSON file of comments (default: stdin)")
    ap.add_argument("--email", default=os.environ.get("BITBUCKET_EMAIL"), help="Bitbucket account email (or $BITBUCKET_EMAIL)")
    ap.add_argument("--dry-run", action="store_true", help="Print what would be posted; make no requests")
    args = ap.parse_args()

    token = os.environ.get("BITBUCKET_API_TOKEN")
    if not args.dry_run and (not token or not args.email):
        print("ERROR: set BITBUCKET_API_TOKEN and --email/$BITBUCKET_EMAIL (or use --dry-run).", file=sys.stderr)
        return 2

    try:
        comments = _load_comments(args.file)
    except (OSError, ValueError, json.JSONDecodeError) as e:
        print(f"ERROR: could not read comments: {e}", file=sys.stderr)
        return 2
    if not comments:
        print("No comments to post.", file=sys.stderr)
        return 0

    url = f"{API_ROOT}/repositories/{args.repo}/pullrequests/{args.pr}/comments"
    auth = _auth_header(args.email or "", token or "")
    failures = 0

    for i, comment in enumerate(comments):
        try:
            payload = _build_payload(comment)
        except (ValueError, TypeError) as e:
            print(f"FAIL [{i}] invalid comment: {e}", file=sys.stderr)
            failures += 1
            continue
        loc = payload.get("inline", {})
        where = f"{loc.get('path')}:{loc.get('to') or loc.get('from')}" if loc else "(top-level)"
        if args.dry_run:
            print(f"DRY  {where}\n     {payload['content']['raw'][:120]}")
            continue
        try:
            res = _post(url, payload, auth)
            print(f"OK   {where} -> comment {res.get('id')}")
        except urllib.error.HTTPError as e:
            print(f"FAIL {where} -> {e.code} {e.read().decode()[:300]}", file=sys.stderr)
            failures += 1
        except urllib.error.URLError as e:
            print(f"FAIL {where} -> {e}", file=sys.stderr)
            failures += 1

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
