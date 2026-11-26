# ==================================================================================
# .FILE
#   Makefile
#
# .SYNOPSIS
#   Project lifecycle commands
#
# .DESCRIPTION
#   Builds, starts, stops and cleans the K3s workloads and the Jenkins LXC
#   container. Starting and stopping is safe to repeat.
#   Reusable targets come from `res/mk/`.
#
# .USAGE
#   make help
#   make build
#   make start | stop | restart
#
# .PARAMETER
#   N/A
#
# .INPUTS
#   project/.env, created from project/.env.example if missing.
#
# .OUTPUTS
#   Depends on the target.
#
# .NOTES
#   Version       : 1.0
#   Author        : @ZouariOmar (zouariomar20@gmail.com)
#   Created       : 2026-11-18
#   Changelog     : e1e38b7
# ==================================================================================
include res/mk/colors.mk \
	res/mk/settings.mk      \
	res/mk/logging.mk       \
	res/mk/versioning.mk    \
	res/mk/envirement.mk    \
	res/mk/fix.mk           \
	res/mk/help.mk

# --- Configuration ---
PROJECT_NAME    := devops-project-management## Project name
SRC_DIR         := project## Source code directory
SCRIPT_DIR      := $(SRC_DIR)/script## Script directory
CONTAINER       := $(PROJECT_NAME)## LXC container name
CONTAINER_SHELL ?= /bin/sh## Shell available inside the container
BACKUP_FILE     := $(SRC_DIR)/backup/$(CONTAINER).tar.gz## Container backup archive
K8S_NAMESPACES  := monitoring database## Namespaces created by the project

# --- Commands ---
KUBECTL := sudo k3s kubectl
container_state = sudo lxc list '^$(CONTAINER)$$' --format csv --columns s

# --- Targets ---

##@ General

.PHONY: all build start stop restart status clean
all: start

build: k8s-start k8s-init lxc-init ## Build the project (first setup)

start: k8s-start lxc-start ## Start the project

stop: lxc-stop k8s-stop ## Stop the project

restart: stop start ## Restart the project

status: k8s-status lxc-status ## Check the project status

clean: lxc-clean k8s-clean ## Delete the container and the namespaces

##@ Linux Container

.PHONY: lxc-init lxc-start lxc-stop lxc-restart lxc-status lxc-shell lxc-logs lxc-export lxc-clean
lxc-init: ## Create and provision the container
	@$(LOG_INFO) "Initializing $(CONTAINER)..."
	$(SCRIPT_DIR)/lxc/create

lxc-start: ## Start the container
	@state=$$($(container_state));                              \
	if [[ "$$state" == RUNNING ]]; then                         \
		$(LOG_INFO) "$(CONTAINER) is already running.";           \
	elif [[ -z "$$state" ]]; then                               \
		$(LOG_ERROR) "$(CONTAINER) not found. Run 'make build'."; \
		exit 1;                                                   \
	else                                                        \
		$(LOG_INFO) "Starting $(CONTAINER)...";                   \
		sudo lxc start $(CONTAINER);                              \
	fi

lxc-stop: ## Stop the container
	@state=$$($(container_state));                   \
	if [[ "$$state" == RUNNING ]]; then              \
		$(LOG_INFO) "Stopping $(CONTAINER)...";        \
		sudo lxc stop $(CONTAINER);                    \
	else                                             \
		$(LOG_INFO) "$(CONTAINER) is not running.";    \
	fi

# Not a prerequisite list: `restart` already depends on `lxc-stop` and `lxc-start`
lxc-restart: ## Restart the container
	@$(MAKE) --no-print-directory lxc-stop
	@$(MAKE) --no-print-directory lxc-start

lxc-status: ## Show the container details
	@$(LOG_INFO) "$(CONTAINER) status..."
	sudo lxc info $(CONTAINER)

lxc-shell: ## Open a shell inside the container
	@$(LOG_INFO) "Connecting to $(CONTAINER)..."
	sudo lxc exec $(CONTAINER) -- $(CONTAINER_SHELL)

lxc-logs: ## Show the Jenkins publishing log (written on boot)
	sudo lxc exec $(CONTAINER) -- cat /var/log/jenkins-publish.log

lxc-export: ## Export a container backup (contains secrets)
	@$(LOG_INFO) "Exporting $(CONTAINER) to $(BACKUP_FILE)..."
	mkdir -p $(dir $(BACKUP_FILE))
	sudo lxc export $(CONTAINER) $(BACKUP_FILE) --instance-only

lxc-clean: ## Delete the container and orphaned veth interfaces
	@$(LOG_INFO) "Cleaning $(CONTAINER)..."
	ip -o link show type veth | awk -F': ' '/state DOWN/ {split($$2, a, "@"); print a[1]}' | xargs -r -n1 sudo ip link delete
	@if $(call CONFIRM,Delete container $(CONTAINER)?); then \
		sudo lxc delete -f $(CONTAINER);                       \
	fi

##@ K8s (K3s)

K8S_SERVICE_TARGETS := k8s-start k8s-stop k8s-restart k8s-enable k8s-disable

.PHONY: $(K8S_SERVICE_TARGETS) k8s-init k8s-status k8s-services k8s-logs k8s-clean
k8s-init: ## Deploy the monitoring and database workloads
	@$(LOG_INFO) "Initializing the K8s workloads..."
	$(SCRIPT_DIR)/k8s/setup

# One shared recipe: the part after `k8s-` is the systemctl action
k8s-start:   ## Start the K3s service
k8s-stop:    ## Stop the K3s service
k8s-restart: ## Restart the K3s service
k8s-enable:  ## Start K3s at system startup
k8s-disable: ## Do not start K3s at system startup

$(K8S_SERVICE_TARGETS): k8s-%:
	@$(LOG_INFO) "K3s service: $*..."
	sudo systemctl $* k3s

k8s-status: ## Show the K3s service, nodes, namespaces and pods
	@$(LOG_INFO) "Checking the Kubernetes cluster..."
	@if ! systemctl is-active --quiet k3s; then \
		$(LOG_WARN) "K3s is not running.";        \
	else                                        \
		$(KUBECTL) get nodes;                     \
		$(KUBECTL) get namespaces;                \
		$(KUBECTL) get pods -A;                   \
	fi

k8s-services: ## List all Kubernetes services
	$(KUBECTL) get services -A

k8s-logs: ## Follow the K3s service logs
	sudo journalctl -u k3s -f

k8s-clean: ## Delete the project namespaces and their data
	@if $(call CONFIRM,Delete namespaces $(K8S_NAMESPACES) and their data?); then \
		$(KUBECTL) delete namespace $(K8S_NAMESPACES) --ignore-not-found;           \
	fi
