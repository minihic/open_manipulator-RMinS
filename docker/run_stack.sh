#!/usr/bin/env bash
set -o pipefail

source /opt/ros/jazzy/setup.bash
source /workspace/install/setup.bash

bringup_pid=""

stop_bringup() {
    trap - EXIT INT TERM
    if [ -n "${bringup_pid}" ] && kill -0 "${bringup_pid}" 2>/dev/null; then
        echo "Stopping arm bringup..."
        kill -INT "${bringup_pid}" 2>/dev/null || true
        wait "${bringup_pid}" 2>/dev/null || true
    fi
}
trap stop_bringup EXIT INT TERM

echo "Starting arm bringup (fake_hardware=${USE_FAKE_HARDWARE:-false}, device=${ROBOT_DEVICE:-/dev/ttyUSB0})..."
ros2 launch open_manipulator_bringup open_manipulator_x.launch.py \
    use_fake_hardware:="${USE_FAKE_HARDWARE:-false}" \
    port_name:="${ROBOT_DEVICE:-/dev/ttyUSB0}" \
    init_position:="${INIT_POSITION:-true}" \
    start_rviz:="${START_RVIZ:-false}" &
bringup_pid=$!

sleep 2
if ! kill -0 "${bringup_pid}" 2>/dev/null; then
    echo "warning: arm bringup exited during startup; continuing with MoveIt"
else
    echo "Arm bringup started (pid ${bringup_pid})."
fi

echo "Starting MoveIt and RViz..."
ros2 launch open_manipulator_moveit_config open_manipulator_x_moveit.launch.py \
    start_rviz:=true
