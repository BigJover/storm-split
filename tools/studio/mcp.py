#!/usr/bin/env python3
"""Talk to Roblox Studio's built-in MCP server (stdio) from the terminal.

    python3 tools/studio/mcp.py tools                      list the tools
    python3 tools/studio/mcp.py call <tool> '<json args>'   call one tool
    python3 tools/studio/mcp.py batch <file.json>           run several calls in one session

A batch file is a JSON list of {"tool": name, "args": {...}, "wait": seconds-after}.
`studio_id` is filled in automatically when a call leaves it out. Image results are
saved as PNG files next to the batch file (or in the current directory) and their
paths printed.

Studio must be open with Assistant > Manage MCP Servers > "Enable Studio as MCP
server" switched on. Studio attaches to the helper a few seconds after it starts, so
every command first waits (up to 60s) until a Studio shows up.
"""
import base64
import json
import os
import subprocess
import sys
import threading
import time

BINARY = "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"
ATTACH_TIMEOUT = 60
CALL_TIMEOUT = 300


class Session:
    def __init__(self):
        self.proc = subprocess.Popen([BINARY], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                     stderr=subprocess.DEVNULL, text=True, bufsize=1)
        self.next_id = 1
        self.replies = {}
        self.lock = threading.Condition()
        threading.Thread(target=self._read, daemon=True).start()
        self.request("initialize", {"protocolVersion": "2024-11-05", "capabilities": {},
                                    "clientInfo": {"name": "dino-hunters-tester", "version": "1"}})
        self.notify("notifications/initialized")

    def _read(self):
        for line in self.proc.stdout:
            try:
                message = json.loads(line)
            except ValueError:
                continue
            if "id" in message:
                with self.lock:
                    self.replies[message["id"]] = message
                    self.lock.notify_all()

    def notify(self, method, params=None):
        payload = {"jsonrpc": "2.0", "method": method}
        if params is not None:
            payload["params"] = params
        self.proc.stdin.write(json.dumps(payload) + "\n")
        self.proc.stdin.flush()

    def request(self, method, params=None, timeout=CALL_TIMEOUT):
        request_id = self.next_id
        self.next_id += 1
        payload = {"jsonrpc": "2.0", "id": request_id, "method": method}
        if params is not None:
            payload["params"] = params
        self.proc.stdin.write(json.dumps(payload) + "\n")
        self.proc.stdin.flush()
        deadline = time.time() + timeout
        with self.lock:
            while request_id not in self.replies:
                left = deadline - time.time()
                if left <= 0:
                    raise TimeoutError(f"{method} timed out after {timeout}s")
                self.lock.wait(left)
            return self.replies.pop(request_id)

    def call(self, tool, args):
        return self.request("tools/call", {"name": tool, "arguments": args})

    def studio_id(self):
        deadline = time.time() + ATTACH_TIMEOUT
        while True:
            reply = self.call("list_roblox_studios", {})
            text = reply.get("result", {}).get("content", [{}])[0].get("text", "{}")
            studios = json.loads(text).get("studios", [])
            if studios:
                return studios[0]["id"]
            if time.time() > deadline:
                raise SystemExit("No Studio attached: is it open with the MCP switch on?")
            time.sleep(2)

    def close(self):
        try:
            self.proc.stdin.close()
        finally:
            self.proc.terminate()


def show(reply, out_dir, label):
    if "error" in reply:
        print("ERROR", json.dumps(reply["error"]))
        return False
    result = reply.get("result", {})
    for index, part in enumerate(result.get("content", [])):
        if part.get("type") == "text":
            print(part["text"])
        elif part.get("type") == "image":
            path = os.path.join(out_dir, f"{label}-{index}.png")
            with open(path, "wb") as handle:
                handle.write(base64.b64decode(part.get("data", "")))
            print(f"[image saved: {path}]")
        else:
            print(f"[{part.get('type')}]")
    return not result.get("isError", False)


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] not in ("tools", "call", "batch"):
        print(__doc__)
        return 2
    session = Session()
    try:
        if sys.argv[1] == "tools":
            session.studio_id()
            for tool in session.request("tools/list").get("result", {}).get("tools", []):
                props = tool.get("inputSchema", {}).get("properties", {})
                print(f"{tool['name']}({', '.join(props)})")
            return 0
        studio = session.studio_id()
        if sys.argv[1] == "call":
            args = json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}
            args.setdefault("studio_id", studio)
            return 0 if show(session.call(sys.argv[2], args), os.getcwd(), sys.argv[2]) else 1
        path = sys.argv[2]
        with open(path) as handle:
            steps = json.load(handle)
        out_dir = os.path.dirname(os.path.abspath(path))
        ok = True
        for number, step in enumerate(steps, 1):
            args = dict(step.get("args", {}))
            args.setdefault("studio_id", studio)
            print(f"--- {number}. {step['tool']}")
            ok = show(session.call(step["tool"], args), out_dir, f"step{number}") and ok
            if step.get("wait"):
                time.sleep(step["wait"])
        return 0 if ok else 1
    finally:
        session.close()


if __name__ == "__main__":
    sys.exit(main())
