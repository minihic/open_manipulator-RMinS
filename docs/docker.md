# Docker environment

The project uses one persistent ROS 2 Jazzy container with a mounted source
tree and named build/install/log volumes. The image contains dependencies only;
it does not copy or build the repository.

## Prerequisites

- Linux host with Docker Engine and the Compose plugin
- your user in the `docker` group
- a local desktop session only if you want RViz/GUI

```bash
sudo usermod -aG docker "$USER"
# log out and back in
docker ps
```

## First run

```bash
cp .env.example .env
# edit device paths and hardware mode if needed
make init
make doctor
make pull       # or: make build
make up
make shell
```

The first `make up` builds the ROS 2 workspace inside the container. Later
source edits are picked up through `--symlink-install`; after adding files or
changing CMake/package metadata run:

```bash
make build-ws
```

## Run the robot stack

Use two host terminals. Both commands run inside the same container.

```bash
# terminal 1
make bringup

# terminal 2
make moveit
```

`make moveit` starts MoveIt with RViz; run `make gui-setup` once per local
desktop session first. `make moveit-headless` starts MoveIt without RViz (use
Foxglove for visualization).

`USE_FAKE_HARDWARE=true` uses the mock hardware. Set it to `false` in `.env`
for the real OpenManipulator-X and set `ROBOT_DEVICE` to the U2D2 device.

## Foxglove

Foxglove needs no X11. Start MoveIt headless first, then the bridge:

```bash
# terminal 2
make moveit-headless

# terminal 3
make foxglove
```

Connect Foxglove Studio to `ws://localhost:8765` (`FOXGLOVE_PORT` in `.env`).

## Optional RViz

RViz needs a local X11 display:

```bash
make gui-setup
make moveit-gui
```

The container runs as root, so `gui-setup` grants the local root user access
with `xhost`. Revoke it with:

```bash
xhost -SI:localuser:root
```

## Devices

Prefer stable paths:

```bash
ls -l /dev/serial/by-id/
ls -l /dev/v4l/by-id/
```

Then set them in `.env`, for example:

```dotenv
ROBOT_DEVICE=/dev/serial/by-id/usb-FTDI_USB__-__Serial_Converter_...
VIDEO_DEVICE=/dev/v4l/by-id/usb-...
```

The container is privileged and mounts `/dev`, so device indices may differ
between machines without changing the compose file.

## Stopping

`make down` moves the arm to the home position used by bringup and then
disables motor torque before stopping the container. The arm is limp after
this, so support it if it is not resting on the platform.

`make clean` does the same and also removes the build/install/log volumes.

## Useful commands

```bash
make ps
make logs
make config
make doctor
make down       # home arm, disable torque, stop container
make clean      # same, also removes build/install/log volumes
```

## Troubleshooting

- `permission denied` on the Docker socket: add your user to the `docker`
  group and log out/in.
- `no /dev/video*` or `no /dev/ttyUSB*`: the device is not connected, or the
  host does not expose it. Check `lsusb` and `v4l2-ctl --list-devices`.
- The container starts and immediately exits: run `make logs`. The workspace
  build probably failed.
- `FastSyncRead Rx Fail` / `SYNC_READ_FAIL` errors from the Dynamixel hardware
  interface: the U2D2 USB latency timer is too high. The entrypoint sets it to
  1 ms automatically; outside the container, set it manually with
  `echo 1 | sudo tee /sys/bus/usb-serial/devices/ttyUSB0/latency_timer`.
- The image cannot be pulled: run `make build` until the GHCR image is
  published by CI.
- RViz cannot open the display: run `make gui-setup` from the local desktop
  session, not over plain SSH.
