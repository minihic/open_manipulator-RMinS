#!/usr/bin/env bash
# Runs inside the container: move the arm to its rest position and disable
# motor torque. Requires arm bringup to still be running.
set -o pipefail

source /opt/ros/jazzy/setup.bash
if [ -f /workspace/install/setup.bash ]; then
    source /workspace/install/setup.bash
fi

echo "Moving arm to rest position..."
ros2 run open_manipulator_bringup shutdown_lander \
    || echo "warning: could not move the arm to the rest position"

echo "Disabling motor torque..."
timeout 10 ros2 service call \
    /dynamixel_hardware_interface/set_dxl_torque \
    std_srvs/srv/SetBool "{data: false}" \
    || echo "warning: could not disable motor torque"
