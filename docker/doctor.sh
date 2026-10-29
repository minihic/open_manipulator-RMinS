#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
    ENV_FILE=".env.example"
fi

if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1090
    . "./$ENV_FILE"
    set +a
fi

FAIL=0
WARN=0

ok() {
    printf '  [ok]   %s\n' "$*"
}

warn() {
    WARN=$((WARN + 1))
    printf '  [warn] %s\n' "$*"
}

bad() {
    FAIL=$((FAIL + 1))
    printf '  [fail] %s\n' "$*"
}

section() {
    printf '\n%s\n' "$*"
}

section "Host"
printf '  arch: %s\n' "$(uname -m)"
printf '  env file: %s\n' "$ENV_FILE"

if command -v docker > /dev/null 2>&1; then
    ok "docker: $(docker --version 2>/dev/null || echo unknown)"
else
    bad "docker is not installed"
fi

if docker compose version > /dev/null 2>&1; then
    ok "docker compose: $(docker compose version 2>/dev/null | head -n 1)"
else
    bad "docker compose is not available"
fi

DOCKER_OK=1
if docker ps > /dev/null 2>&1; then
    ok "docker daemon is reachable by this user"
else
    DOCKER_OK=0
    bad "cannot access the Docker daemon"
    echo "         Run: sudo usermod -aG docker \$USER"
    echo "         Then log out and back in."
fi

if [ "$ENV_FILE" = ".env.example" ]; then
    warn "no .env file; using .env.example defaults. Run: make init"
else
    ok ".env file present"
fi

if [ "$DOCKER_OK" -eq 1 ]; then
    if docker compose --env-file "$ENV_FILE" -f docker/compose.yaml config > /dev/null 2>&1; then
        ok "compose configuration is valid"
    else
        bad "compose configuration is invalid"
    fi
fi

section "Image"
IMAGE="${OPEN_MANIPULATOR_IMAGE:-ghcr.io/minihic/open-manipulator-rmins:latest}"
printf '  image: %s\n' "$IMAGE"
if [ "$DOCKER_OK" -eq 1 ]; then
    if docker image inspect "$IMAGE" > /dev/null 2>&1; then
        ok "image is present locally"
    else
        warn "image is not present. Run: make pull (or make build)"
    fi
fi

section "Container"
if [ "$DOCKER_OK" -eq 1 ] && docker ps --filter 'name=^/open_manipulator_x_project$' --format '{{.Names}}' | grep -qx open_manipulator_x_project; then
    ok "container is running"
    PKGS="$(docker exec open_manipulator_x_project bash -lc \
        'source /opt/ros/jazzy/setup.bash; [ -f /workspace/install/setup.bash ] && source /workspace/install/setup.bash; ros2 pkg list' 2>/dev/null || true)"
    if [ -z "$PKGS" ]; then
        warn "could not list ROS packages in the container"
    else
        for pkg in open_manipulator_bringup open_manipulator_description open_manipulator_demos open_manipulator_moveit_config open_manipulator_teleop moveit_ros_move_group pymoveit2 v4l2_camera usb_cam image_proc apriltag_ros; do
            if grep -qx "$pkg" <<< "$PKGS"; then
                ok "package: $pkg"
            else
                warn "package missing in container: $pkg"
            fi
        done
    fi
else
    warn "container is not running. Run: make up"
fi

section "Devices"
if compgen -G '/dev/video*' > /dev/null; then
    ok "video devices: $(printf '%s ' /dev/video* | sed 's/ $//')"
else
    warn "no /dev/video* found (camera not connected yet)"
fi

if compgen -G '/dev/v4l/by-id/*' > /dev/null; then
    echo "  v4l by-id:"
    for d in /dev/v4l/by-id/*; do
        printf '    %s\n' "$d"
    done
else
    warn "no /dev/v4l/by-id entries found"
fi

if compgen -G '/dev/ttyUSB*' > /dev/null; then
    ok "serial devices: $(printf '%s ' /dev/ttyUSB* | sed 's/ $//')"
else
    warn "no /dev/ttyUSB* found (U2D2 not connected yet)"
fi

if compgen -G '/dev/serial/by-id/*' > /dev/null; then
    echo "  serial by-id:"
    for d in /dev/serial/by-id/*; do
        printf '    %s\n' "$d"
    done
else
    warn "no /dev/serial/by-id entries found"
fi

section "Environment"
printf '  ROS_DOMAIN_ID: %s\n' "${ROS_DOMAIN_ID:-<unset>}"
printf '  ROS_AUTOMATIC_DISCOVERY_RANGE: %s\n' "${ROS_AUTOMATIC_DISCOVERY_RANGE:-<unset>}"
printf '  USE_FAKE_HARDWARE: %s\n' "${USE_FAKE_HARDWARE:-<unset>}"
printf '  ROBOT_DEVICE: %s\n' "${ROBOT_DEVICE:-<unset>}"
printf '  VIDEO_DEVICE: %s\n' "${VIDEO_DEVICE:-<unset>}"
printf '  START_RVIZ: %s\n' "${START_RVIZ:-<unset>}"

if [ "${START_RVIZ:-false}" = "true" ]; then
    section "Display"
    if [ -z "${DISPLAY:-}" ]; then
        bad "START_RVIZ=true but DISPLAY is not set"
    else
        ok "DISPLAY=$DISPLAY"
        if command -v xhost > /dev/null 2>&1; then
            ok "xhost is available"
        else
            warn "xhost is not available; run make gui-setup after installing x11-xserver-utils"
        fi
    fi
fi

section "Summary"
if [ "$FAIL" -gt 0 ]; then
    printf '  %d failure(s), %d warning(s)\n' "$FAIL" "$WARN"
    exit 1
fi

printf '  No critical failures, %d warning(s)\n' "$WARN"
exit 0
