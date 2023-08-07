PORT ?= 8808
HOST ?= 0.0.0.0

MIGRATION_MESSAGE ?= `date +"%Y%m%d_%H%M%S"`
UPGRADE_VERSION ?= head
DOWNGRADE_VERSION ?= -1

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
PROJECT_DIR := $(dir $(MKFILE_PATH))

ifeq (docker-build,$(firstword $(MAKECMDGOALS)))
  IMAGE_NAME := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(IMAGE_NAME):;@:)
endif
IMAGE_NAME := $(if $(IMAGE_NAME),$(IMAGE_NAME),authco_image)

DOCKER_BUILD_CMD := docker build \
	--target runtime \
	-f $(PROJECT_DIR)infra/Dockerfile \
	-t $(IMAGE_NAME) \
	--build-arg INVALIDATE_CACHE_DATE=$(shell date +%Y-%m-%d_%H:%M:%S) \
	$(PROJECT_DIR)
DOCKER_COMPOSE_RESOURCE_CMD := docker-compose \
	--project-directory ${PROJECT_DIR}infra \
	--env-file ${PROJECT_DIR}infra/docker-dev.env \
	-f ${PROJECT_DIR}infra/docker-compose-dev-resources.yaml
DOCKER_COMPOSE_CMD := $(DOCKER_COMPOSE_RESOURCE_CMD) \
	-f ${PROJECT_DIR}infra/docker-compose-dev-api.yaml

.ONESHELL:

goto-project-dir:
	@cd $(PROJECT_DIR)

# Docker related
docker-build: goto-project-dir
	$(DOCKER_BUILD_CMD)
docker-build-debug: goto-project-dir
	$(DOCKER_BUILD_CMD) --no-cache --progress=plain 2>&1 | tee docker-build.log

docker-dev-resource-up:
	$(DOCKER_COMPOSE_RESOURCE_CMD) up -d --remove-orphans
docker-dev-resource-stop:
	$(DOCKER_COMPOSE_RESOURCE_CMD) stop

docker-dev-up:
	$(DOCKER_COMPOSE_CMD) build \
		--build-arg INVALIDATE_CACHE_DATE=$(shell date +%Y-%m-%d_%H:%M:%S)
	$(DOCKER_COMPOSE_CMD) up -d --remove-orphans
docker-dev-up-debug: goto-project-dir
	$(DOCKER_COMPOSE_CMD) build \
		--build-arg INVALIDATE_CACHE_DATE=$(shell date +%Y-%m-%d_%H:%M:%S) \
		--no-cache --progress=plain 2>&1 | tee docker-compose-build.log
	$(DOCKER_COMPOSE_CMD) up -d --remove-orphans
docker-dev-stop: goto-project-dir
	$(DOCKER_COMPOSE_CMD) stop
docker-dev-rm: goto-project-dir
	$(DOCKER_COMPOSE_CMD) rm -svf

docker-dev-ps: goto-project-dir
	$(DOCKER_COMPOSE_CMD) ps

docker-dev-shell: goto-project-dir docker-dev-shell-bash
docker-dev-shell-bash: goto-project-dir
	docker exec -it $(shell $(DOCKER_COMPOSE_CMD) ps -q authco-api-dev) /bin/bash

docker-dev-sp: goto-project-dir docker-dev-shell-plus
docker-dev-shell-plus: goto-project-dir
	docker exec -it $(shell $(DOCKER_COMPOSE_CMD) ps -q authco-api-dev) /usr/local/bin/flask shell-plus

docker-dev-%-log: goto-project-dir
	docker logs authco-$*-dev --follow
docker-dev-nginx-reload: goto-project-dir
	docker exec -it $(shell $(DOCKER_COMPOSE_CMD) ps -q authco-nginx-dev) nginx -s reload
docker-dev-nginx-test: goto-project-dir
	docker exec -it $(shell $(DOCKER_COMPOSE_CMD) ps -q authco-nginx-dev) nginx -t

# DB management related (not released yet)
# db-makemigrations: goto-project-dir
# 	poetry run flask db revision --autogenerate -m $(MIGRATION_MESSAGE)

# db-upgrade: goto-project-dir
# 	poetry run flask db upgrade $(UPGRADE_VERSION)

# db-downgrade: goto-project-dir
# 	poetry run flask db downgrade $(DOWNGRADE_VERSION)

# db-reset: goto-project-dir
# 	poetry run flask db downgrade base

# db-erd-export: goto-project-dir
# 	poetry run flask draw-db-erd

# Dependency management related
dep-install: goto-project-dir
	poetry install --no-root --with dev

dep-upgrade: goto-project-dir
	poetry update

dep-lock: goto-project-dir
	poetry lock --no-update

dep-export: goto-project-dir
	poetry export -f requirements.txt --without-hashes --without=dev --output requirements.txt
	poetry export -f requirements.txt --without-hashes --output requirements-dev.txt

# Devtools
hook-install: goto-project-dir dep-install
	poetry run pre-commit install

hook-update: goto-project-dir
	poetry run pre-commit autoupdate

lint: goto-project-dir
	poetry run pre-commit run --all-files

# Runserver related
runserver: goto-project-dir dep-install
	poetry run gunicorn --bind $(HOST):$(PORT) --reload app:create_app --worker-class uvicorn.workers.UvicornWorker

runserver-dummy: goto-project-dir dep-install
	cd $(PROJECT_DIR)infra/dummy_api_server \
	&& poetry run gunicorn --bind 127.0.0.1:8809 --reload app:create_dummy_app --worker-class uvicorn.workers.UvicornWorker

# test: goto-project-dir dep-install docker-dev-up
# 	poetry run pytest
