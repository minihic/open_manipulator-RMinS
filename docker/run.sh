#!/usr/bin/env bash
# Host-side wrapper for `make run`. Starts the stack inside the container and
# turns Ctrl-C into a safe stop: home the arm, disable torque, then stop the
# launches. The container itself stays up.
set -o pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(dirname -- "$script_dir")"

ENV_FILE="${ENV_FILE:-.env}"
case "$ENV_FILE" in
    /*) ;;
    *) ENV_FILE="$repo_root/$ENV_FILE" ;;
esac

COMPOSE=(docker compose --env-file "$ENV_FILE" -p open-manipulator-x-project -f "$script_dir/compose.yaml")
STACK_PID_FILE=/tmp/open_manipulator_stack.pid
SHUTDOWN_MARKER=/tmp/open_manipulator_stack.shutdown
SHUTDOWN_LOG=/tmp/open_manipulator_shutdown.log
SHUTDOWN_TIMEOUT_SEC=60

in_container() {
    "${COMPOSE[@]}" exec -T ros bash -lc "$1" 2>/dev/null
}

# Echoes "stopping" if the arm is already being landed, "requested" if this
# call started the shutdown, or nothing if the stack is not running.
request_shutdown() {
    in_container "
        if [ -e $SHUTDOWN_MARKER ]; then
            echo stopping
        else
            pid=\$(cat $STACK_PID_FILE 2>/dev/null)
            if [ -n \"\$pid\" ] && grep -qa run_stack.sh /proc/\$pid/cmdline; then
                kill -TERM \$pid && echo requested
            fi
        fi
    "
}

wait_for_shutdown() {
    local waited=0
    while [ "$waited" -lt "$SHUTDOWN_TIMEOUT_SEC" ]; do
        if ! in_container "test -e $STACK_PID_FILE || test -e $SHUTDOWN_MARKER"; then
            return 0
        fi
        sleep 1
        waited=$((waited + 1))
    done
    return 1
}

# The in-container output is gone with the exec session, so print the shutdown
# log the stack script kept for us.
show_shutdown_log() {
    local log
    log="$("${COMPOSE[@]}" exec -T ros bash -lc "cat $SHUTDOWN_LOG 2>/dev/null" 2>/dev/null)"
    [ -n "$log" ] && printf '%s\n' "$log"
    return 0
}

shutdown_stack() {
    local state=""
    local attempt
    # Ignore further interrupts so the arm can finish moving to rest.
    trap '' INT TERM
    echo
    # The stack script may not have written its pid file yet.
    for attempt in 1 2 3; do
        state="$(request_shutdown)"
        [ -n "$state" ] && break
        sleep 1
    done
    case "$state" in
        requested)
            echo "Ctrl-C received: moving the arm to rest and stopping the stack..."
            ;;
        stopping)
            echo "Ctrl-C received: the stack is already stopping; waiting for it..."
            ;;
        *)
            echo "Ctrl-C received: the stack is not running."
            return 0
            ;;
    esac
    if ! wait_for_shutdown; then
        echo "warning: the stack did not stop within ${SHUTDOWN_TIMEOUT_SEC}s; check 'make logs'"
        return 1
    fi
    show_shutdown_log
    echo "The container is still up; use 'make down' to remove it."
}

trap shutdown_stack INT TERM

"${COMPOSE[@]}" exec -T ros bash -lc \
    'exec /workspace/src/open_manipulator/docker/run_stack.sh'
status=$?

# The stack also stops on its own when a launch exits; make sure the arm was
# landed in that case too.
trap '' INT TERM
state="$(request_shutdown)"
if [ "$state" = requested ] || [ "$state" = stopping ]; then
    wait_for_shutdown || true
    show_shutdown_log
fi

exit "$status"
