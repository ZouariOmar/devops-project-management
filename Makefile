# ==================================================================================
# .FILE
#   Makefile
#
# .SYNOPSIS
#   Project lifecycle commands
#
# .DESCRIPTION
#   Builds, runs and cleans the K3s workloads and the Jenkins LXC container.
#   Reusable targets come from `res/mk/`.
#
# .USAGE
#   make help
#   make build
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
	res/mk/settings.mk     \
	res/mk/logging.mk      \
	res/mk/versioning.mk   \
  res/mk/envirement.mk   \
	res/mk/fix.mk          \
	res/mk/help.mk

# --- Configuration ---
PROJECT_NAME          := devops-project-management## Project name
SRC_DIR               := project## Source code directory
SCRIPT_DIR            := $(SRC_DIR)/script## Script directory
CONTAINER             := $(PROJECT_NAME)
BACKUP_FILE           := $(SRC_DIR)/backup/$(CONTAINER).tar.gz
# --- Targets ---

##@ General

.PHONY: all
all: run

.PHONY: build
build: k8s-start k8s-init lxc-init ## Build the project

.PHONY: run
run: k8s-start lxc-start ## Run the project

.PHONY: status
status: k8s-status lxc-status ## Check project status

.PHONY: clean
clean: k8s-clean lxc-clean ## Clean the project

##@ Linux Container

.PHONY: lxc-init
lxc-init: ## Initialize the container
	@$(LOG_INFO) "Initialize $(PROJECT_NAME)..."
	$(SCRIPT_DIR)/lxc/create

.PHONY: lxc-start
lxc-start: ## Start the container
	@$(LOG_INFO) "Starting $(CONTAINER)..."
	sudo lxc start $(CONTAINER)

.PHONY: lxc-stop
lxc-stop: ## Stop the container
	@$(LOG_INFO) "Stopping $(CONTAINER)..."
	sudo lxc stop $(CONTAINER)

.PHONY: lxc-restart
lxc-restart: ## Restart the container
	@$(LOG_INFO) "Restarting $(CONTAINER)..."
	sudo lxc restart $(CONTAINER)

.PHONY: lxc-shell
lxc-shell: ## Open an interactive shell inside the container
	@$(LOG_INFO) "Connecting to $(CONTAINER)..."
	sudo lxc exec $(CONTAINER) -- $(SHELL)

.PHONY: lxc-export
lxc-export: ## Export container backup archive
	@$(LOG_INFO) "Exporting $(CONTAINER) to $(BACKUP_FILE)..."
	sudo lxc export $(CONTAINER) $(BACKUP_FILE) --instance-only

.PHONY: lxc-status
lxc-status: ## Check container status
	@$(LOG_INFO) "$(CONTAINER) status..."
	sudo lxc info $(CONTAINER)

.PHONY: lxc-clean
lxc-clean: ## Stop and delete the container, then remove any orphaned veth network interfaces
	@$(LOG_INFO) "Cleaning $(CONTAINER)..."
	ip -o link show type veth | awk -F': ' '/state DOWN/ {split($$2, a, "@"); print a[1]}' | xargs -r -n1 sudo ip link delete
	@shopt -s nocasematch;                                                              \
	read -ep $$'$(YELLOW)Delete container \'$(CONTAINER)\'? [y/N]...$(TEXT_RESET)' ans; \
	if [[ "$$ans" =~ ^y(es)?$$ ]]; then                                                 \
		sudo lxc delete -f $(CONTAINER);                                                  \
	fi

##@ K8s Workloads

.PHONY: k8s-init
k8s-init: ## Initialize the k8s
	@$(LOG_INFO) "Initialize $(PROJECT_NAME)..."
	$(SCRIPT_DIR)/k8s/setup

.PHONY: k8s-status
k8s-status: ## Check Kubernetes cluster status
	@$(LOG_INFO) "Checking Kubernetes cluster..."
	sudo k3s kubectl get nodes
	sudo k3s kubectl get namespaces
	sudo k3s kubectl get pods -A

.PHONY: k8s-services
k8s-services: ## List all Kubernetes services
	@$(LOG_INFO) "Listing Kubernetes services..."
	sudo k3s kubectl get services -A

.PHONY: k8s-start
k8s-start: ## Start K3s service
	@$(LOG_INFO) "Starting K3s..."
	sudo systemctl start k3s

.PHONY: k8s-stop
k8s-stop: ## Stop K3s service
	@$(LOG_INFO) "Stopping K3s..."
	sudo systemctl stop k3s

.PHONY: k8s-restart
k8s-restart: ## Restart K3s service
	@$(LOG_INFO) "Restarting K3s..."
	sudo systemctl restart k3s

.PHONY: k8s-enable
k8s-enable: ## Enable K3s at system startup
	@$(LOG_INFO) "Enabling K3s..."
	sudo systemctl enable k3s

.PHONY: k8s-disable
k8s-disable: ## Disable K3s at system startup
	@$(LOG_INFO) "Disabling K3s..."
	sudo systemctl disable k3s

.PHONY: k8s-logs
k8s-logs: ## Display K3s service logs
	@$(LOG_INFO) "Displaying K3s logs..."
	sudo journalctl -u k3s -f

.PHONY: k8s-clean
k8s-clean: ## Delete monitoring and database namespaces
	@$(LOG_INFO) "Cleaning Kubernetes namespaces..."
	@read -ep $$'$(YELLOW)Delete monitoring and database namespaces? [y/N]...$(TEXT_RESET)' ans; \
	if [[ "$$ans" =~ ^y(es)?$$ ]]; then \
		sudo k3s kubectl delete namespace monitoring database --ignore-not-found; \
	fi

##@ K3s Engine

k3s-start: ## Start the K3s service
	@$(LOG_INFO) "Starting K3s service..."
	sudo systemctl start k3s

k3s-stop: ## Stop the K3s service
	@$(LOG_INFO) "Stopping K3s service..."
	sudo systemctl stop k3s

k3s-restart: ## Restart the K3s service
	@$(LOG_INFO) "Restarting K3s service..."
	sudo systemctl restart k3s

k3s-status: ## Check K3s service and node status
	@$(LOG_INFO) "Checking K3s status..."
	@sudo systemctl is-active k3s
	@sudo k3s kubectl get nodes

