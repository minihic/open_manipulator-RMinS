SHELL := /bin/bash

ENV_FILE ?= .env
COMPOSE_FILE := docker/compose.yaml
PROJECT := open-manipulator-x-project

COMPOSE := docker compose --env-file $(ENV_FILE) -p $(PROJECT) -f $(COMPOSE_FILE)
EXEC := $(COMPOSE) exec -T ros bash -lc

ROS_SETUP := source /opt/ros/jazzy/setup.bash && source /workspace/install/setup.bash

SHUTDOWN_LANDER_PARAMS := /workspace/src/open_manipulator/docker/shutdown_home.yaml

.PHONY: init doctor pull build up shell build-ws bringup moveit moveit-gui \
	moveit-headless foxglove gui-setup arm-shutdown ps logs config down clean

init:
	@if [ -f $(ENV_FILE) ]; then \
		echo "$(ENV_FILE) already exists"; \
	else \
		cp .env.example $(ENV_FILE); \
		echo "created $(ENV_FILE)"; \
	fi

doctor:
	./docker/doctor.sh

pull:
	$(COMPOSE) pull

build:
	$(COMPOSE) build

up:
	$(COMPOSE) up -d

shell:
	$(COMPOSE) exec ros bash

build-ws:
	$(EXEC) 'source /opt/ros/jazzy/setup.bash && cd /workspace && \
		colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release'

bringup:
	$(EXEC) '$(ROS_SETUP) && \
		ros2 launch open_manipulator_bringup open_manipulator_x.launch.py \
			use_fake_hardware:=$$USE_FAKE_HARDWARE \
			port_name:=$$ROBOT_DEVICE \
			init_position:=$$INIT_POSITION \
			start_rviz:=$$START_RVIZ'

moveit:
	$(EXEC) '$(ROS_SETUP) && \
		ros2 launch open_manipulator_moveit_config open_manipulator_x_moveit.launch.py \
			start_rviz:=true'

moveit-gui: moveit

moveit-headless:
	$(EXEC) '$(ROS_SETUP) && \
		ros2 launch open_manipulator_moveit_config open_manipulator_x_moveit.launch.py \
			start_rviz:=false'

foxglove:
	$(EXEC) '$(ROS_SETUP) && \
		ros2 launch foxglove_bridge foxglove_bridge_launch.xml \
			port:=$$FOXGLOVE_PORT'

gui-setup:
	xhost +SI:localuser:root

arm-shutdown:
	@if $(COMPOSE) ps --status running --services 2>/dev/null | grep -qx ros; then \
		echo "Moving arm to home position..."; \
		$(EXEC) '$(ROS_SETUP) && \
			ros2 run open_manipulator_bringup shutdown_lander \
				--ros-args --params-file $(SHUTDOWN_LANDER_PARAMS)' \
			|| echo "warning: could not move the arm to home"; \
		echo "Disabling motor torque..."; \
		$(EXEC) '$(ROS_SETUP) && \
			timeout 10 ros2 service call \
				/dynamixel_hardware_interface/set_dxl_torque \
				std_srvs/srv/SetBool "{data: false}"' \
			|| echo "warning: could not disable motor torque"; \
	else \
		echo "Container is not running; skipping arm shutdown"; \
	fi

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f

config:
	$(COMPOSE) config

down: arm-shutdown
	$(COMPOSE) down

clean: arm-shutdown
	$(COMPOSE) down -v
