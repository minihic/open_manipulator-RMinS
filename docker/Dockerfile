FROM ros:jazzy-ros-base

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

# Runtime and build dependencies for the OpenManipulator-X project.
# Deliberately no Gazebo and no RealSense.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    python3-colcon-common-extensions \
    python3-numpy \
    python3-opencv \
    python3-rosdep \
    python3-vcstool \
    python3-yaml \
    usbutils \
    v4l-utils \
    ros-jazzy-ament-cmake \
    ros-jazzy-apriltag-msgs \
    ros-jazzy-apriltag-ros \
    ros-jazzy-camera-calibration \
    ros-jazzy-controller-manager \
    ros-jazzy-dynamixel-hardware-interface \
    ros-jazzy-image-proc \
    ros-jazzy-image-transport-plugins \
    ros-jazzy-joint-state-publisher \
    ros-jazzy-joint-state-publisher-gui \
    ros-jazzy-moveit \
    ros-jazzy-moveit-configs-utils \
    ros-jazzy-moveit-kinematics \
    ros-jazzy-moveit-planners \
    ros-jazzy-moveit-ros-move-group \
    ros-jazzy-moveit-ros-visualization \
    ros-jazzy-moveit-ros-warehouse \
    ros-jazzy-moveit-servo \
    ros-jazzy-moveit-setup-assistant \
    ros-jazzy-moveit-simple-controller-manager \
    ros-jazzy-pymoveit2 \
    ros-jazzy-robot-state-publisher \
    ros-jazzy-ros2-control \
    ros-jazzy-ros2-controllers \
    ros-jazzy-rviz2 \
    ros-jazzy-rviz-common \
    ros-jazzy-rviz-default-plugins \
    ros-jazzy-tf2-geometry-msgs \
    ros-jazzy-tf2-ros \
    ros-jazzy-usb-cam \
    ros-jazzy-v4l2-camera \
    ros-jazzy-warehouse-ros-sqlite \
    ros-jazzy-xacro \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONDONTWRITEBYTECODE=1
ENV COLCON_WS=/workspace
WORKDIR /workspace

RUN echo 'source /opt/ros/jazzy/setup.bash' >> /root/.bashrc && \
    echo '[ -f /workspace/install/setup.bash ] && source /workspace/install/setup.bash' >> /root/.bashrc

CMD ["sleep", "infinity"]
