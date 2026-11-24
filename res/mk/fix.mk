# logging.mk - Reusable Fixing Framework for GNU Make
# CREATED: 2026-11-18 01:08
# UPDATED: 2026-11-18 01:08
# DEPPEND: colors.mk

# --- Configuration ---
MAKEFILE_PATH = $(firstword $(MAKEFILE_LIST))

##@ Fix

.PHONY: fix-tab
fix-tab: ## Fix Makefile recipe indentation (convert leading spaces to tabs)
	@$(LOG_INFO) "Fixing indentation in $(MAKEFILE_PATH)..."
	sed -i '/^[[:space:]]/s/^[[:space:]]*/\t/' $(MAKEFILE_PATH)
