#!/usr/bin/env python3
"""Talk to Roblox Studio's built-in MCP server (stdio) from the terminal.

    python3 tools/studio/mcp.py tools                     list the tools
    python3 tools/studio/mcp.py call <tool> '<json args>'  call one

Studio must be open with Assistant Settings > Manage MCP Servers >
"Enable Studio as MCP server" switched on.
"""
import json
import subprocess
import sys

BINARY = "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"
TIMEOUT = 120


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    proc = subprocess.Popen([BINARY], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, text=True, bufsize=1)

    def send(message):
        proc.stdin.write(json.dumps(message) + "\n")
        proc.stdin.flush()

    def reply(want_id):
        while True:
            line = proc.stdout.readline()
            if not line:
                raise SystemExit("StudioMCP closed: " + proc.stderr.read()[-2000:])
            try:
                message = json.loads(line)
            except ValueError:
                continue
            if message.get("id") == want_id:
                return message

    send({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {
        "protocolVersion": "2024-11-05", "capabilities": {},
        "clientInfo": {"name": "dino-hunters-tester", "version": "1"}}})
    reply(1)
    send({"jsonrpc": "2.0", "method": "notifications/initialized"})

    if sys.argv[1] == "tools":
        # StudioMCP answers this only once a Studio has connected to it.
        send({"jsonrpc": "2.0", "id": 2, "method": "tools/list"})
        for tool in reply(2).get("result", {}).get("tools", []):
            props = tool.get("inputSchema", {}).get("properties", {})
            print(f"{tool['name']}({', '.join(props)})")
    elif sys.argv[1] == "call":
        args = json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}
        send({"jsonrpc": "2.0", "id": 2, "method": "tools/call",
              "params": {"name": sys.argv[2], "arguments": args}})
        message = reply(2)
        if "error" in message:
            print("ERROR", json.dumps(message["error"]))
            return 1
        for part in message["result"].get("content", []):
            if part.get("type") == "text":
                print(part["text"])
            else:
                print(f"[{part.get('type')} {len(part.get('data', ''))} bytes]")
    proc.stdin.close()
    proc.terminate()
    return 0


if __name__ == "__main__":
    sys.exit(main())
