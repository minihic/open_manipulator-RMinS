#!/usr/bin/env bash
set -eo pipefail

# ROS and colcon setup scripts are not compatible with `set -u`.
source /opt/ros/jazzy/setup.bash

if [ ! -d /workspace/src/open_manipulator ]; then
    echo "error: /workspace/src/open_manipulator is not mounted" >&2
    exit 1
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
