SHELL := /bin/bash

ENV_FILE ?= .env
COMPOSE_FILE := docker/compose.yaml
PROJECT := open-manipulator-x-project

COMPOSE := docker compose --env-file $(ENV_FILE) -p $(PROJECT) -f $(COMPOSE_FILE)
EXEC := $(COMPOSE) exec -T ros bash -lc

ROS_SETUP := source /opt/ros/jazzy/setup.bash && source /workspace/install/setup.bash

.PHONY: init doctor pull build up shell build-ws bringup moveit moveit-gui \
	foxglove gui-setup ps logs config down clean

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
			start_rviz:=false'

moveit-gui:
	$(EXEC) '$(ROS_SETUP) && \
		ros2 launch open_manipulator_moveit_config open_manipulator_x_moveit.launch.py \
			start_rviz:=true'

foxglove:
	$(EXEC) '$(ROS_SETUP) && \
		ros2 launch foxglove_bridge foxglove_bridge_launch.xml \
			port:=$$FOXGLOVE_PORT'

gui-setup:
	xhost +SI:localuser:root

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f

config:
	$(COMPOSE) config

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down -v
