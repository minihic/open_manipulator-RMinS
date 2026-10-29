#!/usr/bin/env bash
set -eo pipefail

# ROS and colcon setup scripts are not compatible with `set -u`.
source /opt/ros/jazzy/setup.bash

if [ ! -d /workspace/src/open_manipulator ]; then
    echo "error: /workspace/src/open_manipulator is not mounted" >&2
    exit 1
fi

# U2D2/FTDI adapters default to a 16 ms USB latency timer, but the Dynamixel
# hardware interface waits only 10 ms for a fast sync read. Lower the timer so
# real hardware does not fail with SYNC_READ_FAIL.
set_usb_latency_timer() {
    local device="${ROBOT_DEVICE:-/dev/ttyUSB0}"
    local resolved
    local latency

    [ -e "$device" ] || return 0

    resolved="$(readlink -f "$device")"
    case "$(basename "$resolved")" in
        ttyUSB*)
            latency="/sys/bus/usb-serial/devices/$(basename "$resolved")/latency_timer"
            [ -w "$latency" ] || return 0
            echo 1 > "$latency" 2>/dev/null || true
            ;;
    esac
}

if [ "${USE_FAKE_HARDWARE:-false}" != "true" ]; then
    set_usb_latency_timer
fi

cd /workspace

# Build once. Later source edits use symlink-install; use `make build-ws`
# after adding files or changing CMake/package metadata.
if [ ! -f /workspace/install/setup.bash ]; then
    echo "Building ROS 2 workspace..."
    colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release
fi

if [ -f /workspace/install/setup.bash ]; then
    source /workspace/install/setup.bash
fi

exec "$@"
