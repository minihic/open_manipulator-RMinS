#!/usr/bin/env bash
set -euo pipefail

if [ -z "${DISPLAY:-}" ]; then
    echo "error: DISPLAY is not set" >&2
    echo "Run this from a local desktop session with DISPLAY set." >&2
    exit 1
fi

if command -v xdpyinfo > /dev/null 2>&1 && ! xdpyinfo > /dev/null 2>&1; then
    echo "error: cannot connect to X display ${DISPLAY}" >&2
    exit 1
fi

if ! command -v xhost > /dev/null 2>&1; then
    echo "warning: xhost is not installed; the container may not be able to open ${DISPLAY}" >&2
    exit 1
fi

# The container runs as root. Grant only the local root user access.
xhost +SI:localuser:root > /dev/null
echo "Granted root access to X display ${DISPLAY}."
echo "Revoke later with: xhost -SI:localuser:root"
