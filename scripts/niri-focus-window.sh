#!/usr/bin/env bash
# Focus the Preview toplevel that belongs to the given process.
set -u

pid="${1:-}"
if [ -z "$pid" ] || ! command -v niri >/dev/null 2>&1; then
    exit 0
fi

windows="$(niri msg -j windows 2>/dev/null)" || exit 0
id="$(printf '%s' "$windows" | python3 -c '
import json
import sys

pid = int(sys.argv[1])
try:
    windows = json.load(sys.stdin)
except Exception:
    raise SystemExit(0)
for window in windows:
    if window.get("pid") == pid:
        print(window.get("id", ""))
        break
' "$pid")"

if [ -n "$id" ]; then
    niri msg action focus-window --id "$id" >/dev/null 2>&1 || true
fi
