SHELL := /bin/bash

ENV_FILE ?= .env
COMPOSE_FILE := docker/compose.yaml
PROJECT := open-manipulator-x-project

COMPOSE := docker compose --env-file $(ENV_FILE) -p $(PROJECT) -f $(COMPOSE_FILE)
EXEC := $(COMPOSE) exec -T ros bash -lc

ROS_SETUP := source /opt/ros/jazzy/setup.bash && source /workspace/install/setup.bash

.PHONY: init doctor pull build up run shell build-ws bringup moveit moveit-gui \
	moveit-headless gui-setup arm-shutdown ps logs config down clean

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

run: up
	@./docker/x11.sh || \
		echo "warning: X11 access is not configured; RViz may not be able to open the display"
	@echo "Waiting for the ROS workspace to be ready..."
	@for i in $$(seq 1 300); do \
		if $(COMPOSE) exec -T ros test -f /workspace/install/setup.bash 2>/dev/null; then \
			break; \
		fi; \
		sleep 1; \
	done
	@$(COMPOSE) exec -T ros test -f /workspace/install/setup.bash 2>/dev/null || \
		{ echo "error: the workspace build did not finish; run 'make logs'"; exit 1; }
	@if $(COMPOSE) exec -T ros pgrep -f 'open_manipulator_x.*launch.py' >/dev/null 2>&1; then \
		echo "error: the arm stack is already running; run 'make down' first"; exit 1; \
	fi
	@./docker/run.sh

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

gui-setup:
	@./docker/x11.sh

arm-shutdown:
	@if ! $(COMPOSE) ps --status running --services 2>/dev/null | grep -qx ros; then \
		echo "Container is not running; skipping arm shutdown"; \
	elif ! $(COMPOSE) exec -T ros pgrep -f 'open_manipulator_x.launch.py' >/dev/null 2>&1; then \
		echo "Arm bringup is not running; skipping arm shutdown"; \
	else \
		echo "Moving arm to rest position and disabling motor torque..."; \
		$(EXEC) '/workspace/src/open_manipulator/docker/arm_shutdown.sh' \
			|| echo "warning: arm shutdown reported an error"; \
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
