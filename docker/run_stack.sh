#!/usr/bin/env bash
set -o pipefail

source /opt/ros/jazzy/setup.bash
source /workspace/install/setup.bash

stack_pid_file=/tmp/open_manipulator_stack.pid
shutdown_marker=/tmp/open_manipulator_stack.shutdown
shutdown_log=/tmp/open_manipulator_shutdown.log
arm_shutdown=/workspace/src/open_manipulator/docker/arm_shutdown.sh
bringup_pid=""
moveit_pid=""
stopping=0

rm -f "$shutdown_log"

# The stack's output disappears when the exec session ends, so shutdown
# progress is also written to a log the host can print afterwards.
log() {
    printf '%s\n' "$*" | tee -a "$shutdown_log"
}

# Job control puts each launch in its own process group: background jobs would
# otherwise ignore SIGINT, and this way each launch can be stopped on its own.
set -m

# Prints whether a child is still alive (zombies count as stopped).
is_running() {
    local pid="$1"
    local state
    [ -n "$pid" ] || return 1
    state="$(ps -o stat= -p "$pid" 2>/dev/null)"
    [ -n "$state" ] && [ "${state#Z}" = "$state" ]
}

stop_launch() {
    local pid="$1"
    local signal
    local _
    is_running "$pid" || return 0
    for signal in INT TERM KILL; do
        kill -"$signal" -"$pid" 2>/dev/null || kill -"$signal" "$pid" 2>/dev/null || break
        if [ "$signal" = KILL ]; then
            break
        fi
        for _ in $(seq 1 100); do
            is_running "$pid" || break 2
            sleep 0.1
        done
    done
    wait "$pid" 2>/dev/null || true
    return 0
}

shutdown() {
    [ "$stopping" = 1 ] && return 0
    stopping=1
    # Once the arm starts moving to rest, let it finish.
    trap '' INT TERM
    trap - EXIT
    : > "$shutdown_marker"

    log ""
    log "Stopping the arm stack..."
    "$arm_shutdown" 2>&1 | tee -a "$shutdown_log" || true

    log "Stopping MoveIt and arm bringup..."
    stop_launch "$moveit_pid"
    stop_launch "$bringup_pid"
    wait 2>/dev/null || true

    rm -f "$stack_pid_file" "$shutdown_marker"
    log "Arm stack stopped."
}

trap 'shutdown; exit 130' INT TERM
trap shutdown EXIT

echo $$ > "$stack_pid_file"

echo "Starting arm bringup (fake_hardware=${USE_FAKE_HARDWARE:-false}, device=${ROBOT_DEVICE:-/dev/ttyUSB0})..."
ros2 launch open_manipulator_bringup open_manipulator_x.launch.py \
    use_fake_hardware:="${USE_FAKE_HARDWARE:-false}" \
    port_name:="${ROBOT_DEVICE:-/dev/ttyUSB0}" \
    init_position:="${INIT_POSITION:-true}" \
    start_rviz:="${START_RVIZ:-false}" &
bringup_pid=$!

sleep 2
if ! is_running "$bringup_pid"; then
    echo "warning: arm bringup exited during startup; continuing with MoveIt"
else
    echo "Arm bringup started (pid ${bringup_pid})."
fi

echo "Starting MoveIt and RViz..."
ros2 launch open_manipulator_moveit_config open_manipulator_x_moveit.launch.py \
    start_rviz:=true &
moveit_pid=$!

# Ctrl-C arrives as SIGINT/SIGTERM to this script (see docker/run.sh), so the
# arm is landed and the motors are released while the launches are alive.
wait -n "$bringup_pid" "$moveit_pid"
launch_status=$?
echo "A launch exited (status ${launch_status}); stopping the arm stack..."
exit "$launch_status"
