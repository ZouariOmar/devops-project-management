# envirement.mk - Reusable Envirement Framework for GNU Make
# CREATED: 2026-10-03 13:01
# UPDATED: 2026-10-03 13:01
# DEPPEND: settings.mk, logging.mk

# --- Configuration ---
SRC_DIR   ?= project## Source code directory
ENV_FILES ?= $(SRC_DIR)/.env## project .env files

# --- Roles ---
$(ENV_FILES):
	@if [ ! -f $@ ]; then \
	  if [ -f $(@D)/.env.example ]; then \
	    cp $(@D)/.env.example $@ && $(LOG_INFO) "Created $@ from $(@D)/.env.example" \
	  else \
	    $(LOG_WARN) "$(@D)/.env.example missing -- skipped $@" \
	  fi; \
	fi

# --- Loads ---
-include $(ENV_FILES)
export

##@ Envirement

.PHONY: env
env: ## Print every configurable variable (name + description)
	@$(LOG_INFO) "Listing configurable variables...\n"
	@awk '\
	/^[[:space:]]*[A-Z_][A-Z0-9_]*[[:space:]]*[:+?]?=.*##/ { \
		line = $$0; \
		sub(/^[[:space:]]*/, "", line); \
		key = line; \
		sub(/[[:space:]]*[:+?]?=.*/, "", key); \
		desc = line; \
		sub(/^.*##[[:space:]]*/, "", desc); \
		printf "  \033[36m%-24s\033[0m %s\n", key, desc; \
	}' $(MAKEFILE_LIST)
	@$(default_vars)
	@echo ""

.PHONY: env-bootstrap
env-bootstrap: $(ENV_FILES)## Create any missing $(SRC_DIR)/**/.env from its .env.example (never overwrites)

.PHONY: env-make
env-make:  ## Display GNU Make environment variables and their values
	@$(LOG_INFO) "Listing GNU Make environment variables-values...\n"
	@printf "  \033[36m%-22s\033[0m %s\n" \
		"SHELL" "$(SHELL)"                  \
		"SHELLFLAGS" "$(.SHELLFLAGS)"       \
		"OS" "$(OS)"
	@echo ""

.PHONY: env-%
env-%:  ## Print one config variable's value
	@printf "  ${CYAN}%-24s${TEXT_RESET} %s\n" "$*" "$($*)"
