# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

-include .env
export

.ONESHELL:

# Tools
CONTAINER_ENGINE ?= docker

# Directories
CACHE_DIR := $(CURDIR)/.cache
DATA_DIR := $(CACHE_DIR)/data
TMP_DIR := $(CACHE_DIR)/tmp

# K0SCTL
K0SCTL_USERNAME ?= admin
K0SCTL_IDENTITY_PATH ?= $(CURDIR)/.ssh/id_rsa
K0SCTL_BASE_CONFIG_PATH := $(CURDIR)/k0s/k0s.Cluster.yaml
K0SCTL_CONFIG_OUTPUT := $(CACHE_DIR)/k0sctl/config.yaml
K0SCTL_KUBECONFIG := $(CACHE_DIR)/.kube/config
KUBECONFIG := $(K0SCTL_KUBECONFIG)
K0SCTL_CLUSTER_NAME ?= infra

help: ## Show this help message
	@echo "Homelab Infrastructure Tasks"
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
.PHONY: help

k0s-apply: generate-config ## Apply k0s cluster configuration
	k0sctl apply -c $(K0SCTL_CONFIG_OUTPUT)
.PHONY: k0s-apply

k0s-reset: generate-config ## Reset k0s cluster
	k0sctl reset --force -c $(K0SCTL_CONFIG_OUTPUT)
.PHONY: k0s-reset

k0s-config: generate-config ## Generate k0s kubeconfig
	mkdir -p $$(dirname $(K0SCTL_KUBECONFIG))
	install -m 0600 <(k0sctl kubeconfig -c $(K0SCTL_CONFIG_OUTPUT)) $(K0SCTL_KUBECONFIG)
.PHONY: k0s-config

flux-apply: ## Apply Flux configuration
	kubectl apply -k flux
.PHONY: flux-apply

generate-config: generate-k0s ## Generate k0sctl configuration
	mkdir -p $$(dirname $(K0SCTL_CONFIG_OUTPUT))
	kustomize build k0s > $(K0SCTL_CONFIG_OUTPUT)
.PHONY: generate-config

generate-k0s: ## Generate k0s base configuration
	k0sctl init --k0s \
		--user $(K0SCTL_USERNAME) \
		-i $(K0SCTL_IDENTITY_PATH) \
		--cluster-name "$(K0SCTL_CLUSTER_NAME)" \
		$(K0SCTL_HOSTS) > $(K0SCTL_BASE_CONFIG_PATH)
.PHONY: generate-k0s

clean: ## Clean generated files
	rm -rf $(CACHE_DIR)
.PHONY: clean

reuse-apply:
	reuse annotate --copyright NONE --license Unlicense -r "$(PROJECT_ROOT)" --fallback-dot-license
.PHONY: reuse-apply
