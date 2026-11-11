#!/usr/bin/env bash
# Launch the standalone Preview executable, or let it forward its paths to an
# already-running instance.
set -u

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
script_dir="$(cd "$(dirname "$script_path")" && pwd)"

bin=""
if [ -x "$script_dir/../build/preview" ]; then
    bin="$script_dir/../build/preview"
elif [ -x "$script_dir/../build-standalone/preview" ]; then
    bin="$script_dir/../build-standalone/preview"
elif [ -x "$HOME/.local/lib/preview/preview" ]; then
    bin="$HOME/.local/lib/preview/preview"
else
    echo "preview: executable not found; run ./install.sh or build with CMake" >&2
    exit 1
fi

if [ "${PREVIEW_FOREGROUND:-0}" = "1" ]; then
    exec "$bin" "$@"
fi

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/preview"
log_file="$state_dir/preview.log"
mkdir -p "$state_dir"

if command -v systemd-run >/dev/null 2>&1; then
    env_args=()
    if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
        env_args+=(--setenv="XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR")
    fi
    if [ -n "${WAYLAND_DISPLAY:-}" ]; then
        env_args+=(--setenv="WAYLAND_DISPLAY=$WAYLAND_DISPLAY")
    fi
    if [ -n "${DISPLAY:-}" ]; then
        env_args+=(--setenv="DISPLAY=$DISPLAY")
    fi
    if [ -n "${NIRI_SOCKET:-}" ]; then
        env_args+=(--setenv="NIRI_SOCKET=$NIRI_SOCKET")
    fi
    if [ -n "${XDG_SESSION_TYPE:-}" ]; then
        env_args+=(--setenv="XDG_SESSION_TYPE=$XDG_SESSION_TYPE")
    fi
    if [ -n "${PATH:-}" ]; then
        env_args+=(--setenv="PATH=$PATH")
    fi
    if [ -n "${LANG:-}" ]; then
        env_args+=(--setenv="LANG=$LANG")
    fi
    if [ -n "${LC_ALL:-}" ]; then
        env_args+=(--setenv="LC_ALL=$LC_ALL")
    fi
    if [ -n "${LANGUAGE:-}" ]; then
        env_args+=(--setenv="LANGUAGE=$LANGUAGE")
    fi

    unit="preview-$(date +%s)-$$-$RANDOM"
    if systemd-run --user --unit="$unit" --collect --no-block \
        --description="Preview image and video viewer" \
        --property=StandardOutput=append:"$log_file" \
        --property=StandardError=append:"$log_file" \
        --working-directory="$PWD" \
        "${env_args[@]}" \
        "$bin" "$@" >/dev/null 2>&1; then
        exit 0
    fi
fi

setsid "$bin" "$@" >>"$log_file" 2>&1 </dev/null &
exit 0
