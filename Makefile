# =========================================================
# devops-project-management makefile
# CREATED: 2026-11-18 00:16
# UPDATED: 2026-11-18 00:16
# =========================================================
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
build: lxc-init k8s-init ## Build the project

.PHONY: run
run: lxc-start ## Run the project

.PHONY: status
status: lxc-status ## Check project status

.PHONY: clean
clean: lxc-clean ## Clean the project
	@$(LOG_INFO) "Cleaning $(PROJECT_NAME)..."
	rm -f $(BACKUP_FILE)

##@ Linux Container

.PHONY: lxc-init
lxc-init: ## Initialize the container
	@$(LOG_INFO) "Initialize $(PROJECT_NAME)..."
	$(SCRIPT_DIR)/00_lc_init

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
	$(SCRIPT_DIR)/00_k8s_init

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

