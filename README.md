# OpenManipulator-X AprilTag Grasp Project

A project fork of the RMinS OpenManipulator course repository, focused on a
single robot: the classic **OpenManipulator-X** mounted on the course base.

The target application is:

1. detect an AprilTag on a target with a gripper-mounted UVC camera,
2. track the target,
3. plan and execute a grasp with MoveIt 2.

## Status

This fork is being rebuilt for a smaller, Docker-based project environment.

- [x] Fork created
- [x] Course-only packages and assets removed
- [x] Minimal Docker environment
- [ ] Camera and AprilTag packages
- [ ] Hand-eye calibration
- [ ] Tag tracking and grasping

The camera/AprilTag integration is the next phase. The arm stack can already be
built and run in the container.

## Robot

- **Arm:** OpenManipulator-X (4 DOF + gripper), not the newer OMX variants.
- **Base:** course platform (`meshes/platform/joseph.dae`) and the existing
  `world -> base_link -> link1` transforms.
- **Control:** U2D2 / Dynamixel hardware, `ros2_control`.
- **Camera:** InnoMaker UVC camera, mounted on the gripper (mount transform to
  be calibrated).

## Repository layout

```text
open_manipulator_bringup/        OpenManipulator-X launch and configuration
open_manipulator_description/    OpenManipulator-X URDF, meshes, RViz config
open_manipulator_moveit_config/  MoveIt 2 configuration
open_manipulator_demos/          Small MoveIt examples and validation helpers
open_manipulator_teleop/         Keyboard teleoperation
docker/                          Minimal Docker environment
docs/                            Docker and project notes
```

Future additions:

```text
open_manipulator_perception/     Camera, image_proc, AprilTag detection
project_apps/                    Target tracking and grasp application
```

## What was removed

- All non-OpenManipulator-X robots: OMX-F, OMX-L, OMY-3M, OMY-F3M, OMY-L100,
  and the leader/follower AI packages.
- Gazebo launch files, worlds, and Gazebo-specific URDF extensions.
- RealSense support.
- The Qt GUI, playground, self-collision package, and leader/follower
  controllers.
- The old course Docker setup and course documentation.

## Docker quick start

The primary environment is a single persistent ROS 2 Jazzy container. It uses
a mounted source tree and named build/install/log volumes. The image contains
dependencies only; it does not copy or build the repository.

Prerequisites: Linux, Docker Engine, the Compose plugin, and your user in the
`docker` group.

```bash
cp .env.example .env
# edit device paths and USE_FAKE_HARDWARE in .env
make init
make doctor
make pull       # or: make build
make up
make shell
```

The first `make up` builds the workspace inside the container. After source
changes, use `make build-ws` for new files or CMake/package metadata changes.

Run the arm stack in two host terminals:

```bash
# terminal 1
make bringup

# terminal 2
make moveit
```

`USE_FAKE_HARDWARE=true` uses mock hardware. Set it to `false` and point
`ROBOT_DEVICE` at the U2D2 device for the real arm.

For headless visualization, run `make foxglove` and connect Foxglove Studio to
`ws://localhost:8765`. For optional RViz, run `make gui-setup` and then
`make moveit-gui` from a local desktop session.

See [docs/docker.md](docs/docker.md) for device paths, GUI setup, and
troubleshooting.

## Native build (alternative)

The packages target **ROS 2 Jazzy** and can also be built in a normal workspace:

```bash
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws/src
git clone git@github.com:minihic/open_manipulator-RMinS.git open_manipulator
cd ~/ros2_ws
rosdep install --from-paths src --ignore-src -y
colcon build --symlink-install
source install/setup.bash
```

## Provenance and license

This repository is a fork of
[`snt-spacer/open_manipulator-RMinS`](https://github.com/snt-spacer/open_manipulator-RMinS),
which is derived from the ROBOTIS OpenManipulator project.

The upstream code and this fork are distributed under the Apache License 2.0.
See `LICENSE` and `NOTICE`.
