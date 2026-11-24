# docker.mk - Reusable Docker Framework for GNU Make
# CREATED: 2026-10-12 17:05
# UPDATED: 2026-10-12 17:06
# DEPPEND: logging.mk

# --- Configuration ---
SRC_DIR             ?= project## Source code directory
DOCKER_COMPOSE_FILE ?= $(SRC_DIR)/docker/docker-compose.yml## Project docker compose file

# --- Commands ---
DOCKER_COMPOSE_CMD = docker compose -f $(DOCKER_COMPOSE_FILE)## Docker compose command

##@ Docker

.PHONY: docker-up
docker-up: ## Start docker compose stack in the background
	@$(LOG_INFO) "Starting the docker compose stack..."
	$(DOCKER_COMPOSE_CMD) up -d

.PHONY: docker-up-%
docker-up-%: ## Start docker compose service in the background
	@$(LOG_INFO) "Starting the docker compose $* service..."
	$(DOCKER_COMPOSE_CMD) up -d $*

.PHONY: docker-down
docker-down:  ## Stop the docker compose stack
	@$(LOG_INFO) "Stopping the docker compose stack..."
	$(DOCKER_COMPOSE_CMD) down

.PHONY: docker-down-%
docker-down-%:  ## Stop the docker compose service
	@$(LOG_INFO) "Stopping the docker compose $* service..."
	$(DOCKER_COMPOSE_CMD) down $*

.PHONY: docker-logs
docker-logs: ## Show docker compose stack logs
	@$(LOG_INFO) "Showing docker compose stack logs..."
	$(DOCKER_COMPOSE_CMD) logs

.PHONY: docker-logs-%
docker-logs-%: ## Show docker comose service logs
	@$(LOG_INFO) "Showing docker compose $* service logs..."
	$(DOCKER_COMPOSE_CMD) logs -f $*
