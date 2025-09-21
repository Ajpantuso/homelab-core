# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

-include .env
export

.ONESHELL:

# Tools
CONTAINER_ENGINE ?= docker

help: ## Show this help message
	@echo "Homelab Infrastructure Tasks"
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
.PHONY: help

flux-apply: ## Apply Flux configuration
	kubectl apply -k flux
.PHONY: flux-apply

reuse-apply:
	reuse annotate --copyright NONE --license Unlicense -r "$(PROJECT_ROOT)" --fallback-dot-license
.PHONY: reuse-apply
