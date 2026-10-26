#!/usr/bin/env python3
"""Upload approved art to Roblox via the Open Cloud Assets API (PLAN 11a T147, #422/#437/#438).

    python3 tools/art/upload.py --dry-run    # show the plan; never touches the network
    python3 tools/art/upload.py              # upload approved, changed models

For each manifest model whose batch is in manifest["approved"] (Jovan approves a batch's
previews first, #438) and whose geometry hash differs from the one last uploaded:
create a Model asset from out/<kind>/<key>.fbx (or a new version of its existing asset),
poll the operation until done, store the asset id + hash in manifest.json, then regenerate
src/shared/ArtIds.luau (write_ids.py). Unapproved or unchanged models are skipped.

Key + creator id: env ROBLOX_API_KEY / ROBLOX_CREATOR_ID, else ~/.config/dinohunters/
{opencloud_key, creator_id}; that folder must be mode 700. With no key this prints
"no key yet — previews only" and exits 0. The key is never printed or logged; every
error message passes through redact(). See README.md for verified vs assumed API details.
"""

import json
import os
import stat
import sys
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

import write_ids

ART = Path(__file__).resolve().parent
MANIFEST = ART / "manifest.json"
CONFIG = Path.home() / ".config" / "dinohunters"
API = "https://apis.roblox.com/assets/v1"
POLL_SECONDS, POLL_TRIES = 3, 60

_secrets = []


def redact(text):
    for s in _secrets:
        if s:
            text = str(text).replace(s, "[redacted]")
    return text


def credentials():
    """(key, creator) or None. Raises SystemExit if the config folder is too open."""
    key, creator = os.environ.get("ROBLOX_API_KEY"), os.environ.get("ROBLOX_CREATOR_ID")
    if not key and (CONFIG / "opencloud_key").exists():
        mode = stat.S_IMODE(CONFIG.stat().st_mode)
        if mode != 0o700:
            sys.exit(f"refusing: {CONFIG} is mode {mode:o}, must be 700 (chmod 700 {CONFIG})")
        key = (CONFIG / "opencloud_key").read_text().strip()
        if not creator and (CONFIG / "creator_id").exists():
            creator = (CONFIG / "creator_id").read_text().strip()
    if not key:
        return None
    _secrets.append(key)
    if not creator or not creator.isdigit():
        sys.exit("key found but no numeric creator id (ROBLOX_CREATOR_ID or creator_id file)")
    return key, creator


def plan(manifest):
    """[(name, entry, action)] where action is upload / update / skip reason."""
    approved = set(manifest.get("approved", []))
    rows = []
    for name, entry in sorted(manifest.get("models", {}).items()):
        if entry["batch"] not in approved:
            rows.append((name, entry, f"waiting for approval of batch {entry['batch']}"))
        elif entry.get("uploadedHash") == entry["hash"]:
            rows.append((name, entry, "unchanged"))
        elif not (ART / "out" / f"{name}.fbx").exists():
            rows.append((name, entry, "no FBX: run tools/art/build.sh first"))
        else:
            rows.append((name, entry, "update" if entry.get("asset") else "upload"))
    return rows


def _multipart(request, fbx):
    boundary = uuid.uuid4().hex
    parts = [
        f'--{boundary}\r\nContent-Disposition: form-data; name="request"\r\n'
        f"Content-Type: application/json\r\n\r\n{json.dumps(request)}\r\n".encode(),
        f'--{boundary}\r\nContent-Disposition: form-data; name="fileContent"; filename="{fbx.name}"\r\n'
        "Content-Type: model/fbx\r\n\r\n".encode() + fbx.read_bytes() + b"\r\n",
        f"--{boundary}--\r\n".encode(),
    ]
    return b"".join(parts), f"multipart/form-data; boundary={boundary}"


def _call(method, url, key, body=None, ctype=None):
    req = urllib.request.Request(url, data=body, method=method, headers={"x-api-key": key})
    if ctype:
        req.add_header("Content-Type", ctype)
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read() or b"{}")
    except urllib.error.HTTPError as err:
        detail = err.read()[:300].decode(errors="replace")
        raise RuntimeError(redact(f"{method} {url} -> HTTP {err.code}: {detail}")) from None


def upload(name, entry, key, creator):
    fbx = ART / "out" / f"{name}.fbx"
    kind, model_key = name.split("/", 1)
    if entry.get("asset"):  # new version of the same asset: the id in ArtIds stays put
        body, ctype = _multipart({"assetId": str(entry["asset"])}, fbx)
        op = _call("PATCH", f"{API}/assets/{entry['asset']}", key, body, ctype)
    else:
        request = {
            "assetType": "Model",
            "displayName": f"DinoHunters {kind} {model_key}",
            "description": f"Dino Hunters art: {name} (tools/art, hash {entry['hash']})",
            "creationContext": {"creator": {"userId": creator}},
        }
        body, ctype = _multipart(request, fbx)
        op = _call("POST", f"{API}/assets", key, body, ctype)
    op_id = op.get("operationId") or op.get("path", "").rsplit("/", 1)[-1]
    for _ in range(POLL_TRIES):
        if op.get("done"):
            break
        time.sleep(POLL_SECONDS)
        op = _call("GET", f"{API}/operations/{op_id}", key)
    if not op.get("done"):
        raise RuntimeError(f"{name}: operation {op_id} not done after {POLL_SECONDS * POLL_TRIES} s")
    if "error" in op:
        raise RuntimeError(redact(f"{name}: {op['error']}"))
    asset = op.get("response", {}).get("assetId") or entry.get("asset")
    if not asset:
        raise RuntimeError(redact(f"{name}: no assetId in {json.dumps(op)[:300]}"))
    return int(asset)


def main(argv):
    dry = "--dry-run" in argv
    manifest = json.loads(MANIFEST.read_text())
    rows = plan(manifest)
    creds = None if dry else credentials()
    if not dry and creds is None:
        print("no key yet — previews only")
    for name, entry, action in rows:
        print(f"  {name:<20} {entry['tris']:>5} tris  {action}")
    if dry or creds is None:
        return 0
    failed = 0
    for name, entry, action in rows:
        if action not in ("upload", "update"):
            continue
        try:
            entry["asset"] = upload(name, entry, *creds)
            entry["uploadedHash"] = entry["hash"]
            MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
            print(f"  {name}: asset {entry['asset']}")
        except Exception as err:  # noqa: BLE001 - report, keep going, never leak the key
            failed += 1
            print(f"  {name}: FAILED {redact(err)}")
    write_ids.main([])
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
