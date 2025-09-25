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

update-k0s-version:
	@VERSION=$$(curl -sSL https://api.github.com/repos/k0sproject/k0s/releases/latest | jq -r .name) && \
	yq -r ".k0s.version = \"$$VERSION\"" --indentless -iy config.yaml
.PHONY: update-k0s-version

reuse-apply:
	reuse annotate --copyright NONE --license Unlicense -r "$(PROJECT_ROOT)" --fallback-dot-license
.PHONY: reuse-apply
