# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

-include .env
export

.ONESHELL:

# Tools
CONTAINER_ENGINE ?= docker
DOWNLOAD_FROM_URL := $(CURDIR)/hack/download_from_url.sh

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
K0S_BM_BUTANE_PATH := $(CURDIR)/ignition/k0s-bm.bu
K0S_VM_BUTANE_PATH := $(CURDIR)/ignition/k0s-vm.bu

# CoreOS image builder
COREOS_ISO_PATH := $(TMP_DIR)/coreos.iso
COREOS_ISO_OUTPUT := coreos.iso
COREOS_VERSION := 40.20240519.3.0
TARGET_SYSTEM_ARCH := x86_64
COREOS_DOWNLOAD_URL := https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/$(COREOS_VERSION)/$(TARGET_SYSTEM_ARCH)
COREOS_ISO_URL := $(COREOS_DOWNLOAD_URL)/fedora-coreos-$(COREOS_VERSION)-live.$(TARGET_SYSTEM_ARCH).iso
COREOS_KERNEL_URL := $(COREOS_DOWNLOAD_URL)/fedora-coreos-$(COREOS_VERSION)-live-kernel-$(TARGET_SYSTEM_ARCH)
COREOS_INITRAMFS_URL := $(COREOS_DOWNLOAD_URL)/fedora-coreos-$(COREOS_VERSION)-live-initramfs.$(TARGET_SYSTEM_ARCH).img
COREOS_ROOTFS_URL := $(COREOS_DOWNLOAD_URL)/fedora-coreos-$(COREOS_VERSION)-live-rootfs.$(TARGET_SYSTEM_ARCH).img

# Fedora Server image builder
FEDORA_VERSION := 40
FEDORA_DOWNLOAD_URL := https://download.fedoraproject.org/pub/fedora/linux/releases/$(FEDORA_VERSION)/Server/x86_64/os/images/pxeboot
FEDORA_KERNEL_URL := $(FEDORA_DOWNLOAD_URL)/vmlinuz
FEDORA_INITRD_URL := $(FEDORA_DOWNLOAD_URL)/initrd.img

# ARM image builder
ARM_INSTALL_RELEASE := 40
ARM_INSTALL_DEVICE := /dev/sda

# PXE artifacts
PXE_ROOT_DIR := $(DATA_DIR)/os
PXE_COREOS_DIR := $(PXE_ROOT_DIR)/fedora/coreos/$(COREOS_VERSION)/$(TARGET_SYSTEM_ARCH)
PXE_FEDORA_DIR := $(PXE_ROOT_DIR)/fedora/server/$(FEDORA_VERSION)/$(TARGET_SYSTEM_ARCH)
K0S_BM_IGNITION_OUTPUT := $(PXE_COREOS_DIR)/k0s-bm.ign
K0S_VM_IGNITION_OUTPUT := $(PXE_COREOS_DIR)/k0s-vm.ign
COREOS_KERNEL_OUTPUT := $(PXE_COREOS_DIR)/k0s-live-kernel
COREOS_INITRAMFS_OUTPUT := $(PXE_COREOS_DIR)/k0s-live-initramfs.img
COREOS_ROOTFS_OUTPUT := $(PXE_COREOS_DIR)/k0s-live-rootfs.img
FEDORA_KERNEL_OUTPUT := $(PXE_FEDORA_DIR)/vmlinuz
FEDORA_INITRD_OUTPUT := $(PXE_FEDORA_DIR)/initrd.img
CORE_IGNITION_PATH := $(PXE_COREOS_DIR)/core.ign
CORE_BUTANE_PATH := $(CURDIR)/ignition/core.bu
PKI_IGNITION_PATH := $(PXE_COREOS_DIR)/pki.ign
PKI_BUTANE_PATH := $(CURDIR)/ignition/pki.bu

help: ## Show this help message
	@echo "Homelab Infrastructure Tasks"
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
.PHONY: help

apply-pxe: coreos-generate-pxe hypervisor-generate-pxe ## Apply PXE configuration to core server
	scp -i $(K0SCTL_IDENTITY_PATH) -Cr $(PXE_ROOT_DIR) $(K0SCTL_USERNAME)@core:/srv/www
.PHONY: apply-pxe

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

coreos-generate-pxe: k0s-generate-ignition core-generate-ignition pki-generate-ignition ## Generate CoreOS PXE artifacts
	mkdir -p $(PXE_COREOS_DIR)
	"$(DOWNLOAD_FROM_URL)" "$(COREOS_KERNEL_URL)" "$(COREOS_KERNEL_OUTPUT)"
	"$(DOWNLOAD_FROM_URL)" "$(COREOS_ROOTFS_URL)" "$(COREOS_ROOTFS_OUTPUT)"
	if [ -f "$(COREOS_INITRAMFS_OUTPUT)" ]; then \
		rm "$(COREOS_INITRAMFS_OUTPUT)"; \
	fi
	coreos-installer pxe customize \
		--dest-console ttyS0,115200n8 \
		--dest-console tty0 \
		-o "$(COREOS_INITRAMFS_OUTPUT)" <(curl -sL $(COREOS_INITRAMFS_URL))
	chmod 0644 "$(COREOS_INITRAMFS_OUTPUT)"
.PHONY: coreos-generate-pxe

hypervisor-generate-pxe: ## Generate hypervisor PXE artifacts
	mkdir -p "$(PXE_FEDORA_DIR)"
	export install_device="/dev/nvme0n1" && \
	export labadm_key="$$(cat $(LABADM_PUBLIC_KEY))" && \
	export labadm_passwd="$(LABADM_PASSWD)" && \
	mo "$(CURDIR)/kickstart/hypervisor.mustache" > "$(PXE_FEDORA_DIR)/hypervisor.ks"
	ksvalidator "$(PXE_FEDORA_DIR)/hypervisor.ks"
	"$(DOWNLOAD_FROM_URL)" "$(FEDORA_KERNEL_URL)" "$(FEDORA_KERNEL_OUTPUT)"
	"$(DOWNLOAD_FROM_URL)" "$(FEDORA_INITRD_URL)" "$(FEDORA_INITRD_OUTPUT)"
.PHONY: hypervisor-generate-pxe

core-arm-install: core-generate-ignition ## Install CoreOS on ARM device
	sudo env PATH="$(PATH)" coreos-installer install \
		-a aarch64 -s stable \
		-i "$(CORE_IGNITION_PATH)" \
		--append-karg nomodeset "$(ARM_INSTALL_DEVICE)"
	tmp="$$(mktemp -d)"; \
	mkdir -p "$${tmp}/boot/efi/"; \
	sudo dnf install -y \
		--downloadonly \
		--forcearch=aarch64 \
		--release="$(ARM_INSTALL_RELEASE)" \
		--destdir="$${tmp}" \
		uboot-images-armv8 bcm283x-firmware bcm283x-overlays; \
	for rpm in "$${tmp}"/*rpm; do \
		rpm2cpio "$${rpm}" | cpio -idv -D "$${tmp}"; \
	done; \
	mv "$${tmp}/usr/share/uboot/rpi_arm64/u-boot.bin" \
		"$${tmp}/boot/efi/rpi-u-boot.bin"; \
	part=$$( \
		lsblk "$(ARM_INSTALL_DEVICE)" -J -oLABEL,PATH  | \
		jq -r '.blockdevices[] | select(.label == "EFI-SYSTEM")'.path \
	); \
	mnt="$$(mktemp -d)"; \
	mkdir "$${mnt}"; \
	sudo mount "$${part}" "$${mnt}"; \
	sudo rsync -avh --ignore-existing "$${tmp}/boot/efi/" "$${mnt}"; \
	sudo umount "$${part}"; \
	rm -rf $${tmp}; \
	rm -rf $${mnt}
.PHONY: core-arm-install

k0s-generate-ignition: common-pre-gen-ignition ## Generate k0s ignition files
	mkdir -p $$(dirname $(K0S_BM_IGNITION_OUTPUT))
	butane \
		--pretty --strict \
		--files-dir $(DATA_DIR) \
		< $(K0S_BM_BUTANE_PATH) \
		> $(K0S_BM_IGNITION_OUTPUT)
	mkdir -p $$(dirname $(K0S_VM_IGNITION_OUTPUT))
	butane \
		--pretty --strict \
		--files-dir $(DATA_DIR) \
		< $(K0S_VM_BUTANE_PATH) \
		> $(K0S_VM_IGNITION_OUTPUT)
.PHONY: k0s-generate-ignition

core-generate-ignition: common-pre-gen-ignition ## Generate core ignition file
	mkdir -p $$(dirname $(CORE_IGNITION_PATH))
	butane \
		--pretty --strict \
		--files-dir $(DATA_DIR) \
		< $(CORE_BUTANE_PATH) \
		> $(CORE_IGNITION_PATH)
.PHONY: core-generate-ignition

pki-generate-ignition: common-pre-gen-ignition ## Generate PKI ignition file
	mkdir -p $$(dirname $(PKI_IGNITION_PATH))
	butane \
		--pretty --strict \
		--files-dir $(DATA_DIR) \
		< $(PKI_BUTANE_PATH) \
		> $(PKI_IGNITION_PATH)
.PHONY: pki-generate-ignition

common-pre-gen-ignition: ## Prepare common ignition generation dependencies
	mkdir -p $(DATA_DIR)
	cp $(LABADM_PUBLIC_KEY) $(DATA_DIR)/labadm.pub
	cp -R overlays/ $(DATA_DIR)
	$(CONTAINER_ENGINE) build -q -t ipxe -f - "$(CURDIR)" << EOF
		FROM registry.fedoraproject.org/fedora
		RUN dnf install -y ipxe-bootimgs-x86 ipxe-bootimgs-aarch64
		VOLUME /out
		CMD ["sh", "-c", "cp /usr/share/ipxe/{undionly.kpxe,ipxe-x86_64.efi,ipxe-i386.efi} /out"]
	EOF
	$(CONTAINER_ENGINE) run --rm -v $(DATA_DIR)/overlays/core/var/lib/tftpboot:/out:z localhost/ipxe
.PHONY: common-pre-gen-ignition

coreos-generate-iso: ## Generate CoreOS ISO
	mkdir -p "$(TMP_DIR)"
	"$(DOWNLOAD_FROM_URL)" "$(COREOS_ISO_URL)" "$(COREOS_ISO_PATH)"
	coreos-installer iso customize \
		--dest-console ttyS0,115200n8 \
		--dest-console tty0 \
		-o $(COREOS_ISO_OUTPUT) $(COREOS_ISO_PATH)
.PHONY: coreos-generate-iso

clean: ## Clean generated files
	rm -rf $(CACHE_DIR)
	rm -f $(COREOS_ISO_OUTPUT)
.PHONY: clean

reuse-apply:
	reuse annotate --copyright NONE --license Unlicense -r "$(PROJECT_ROOT)" --fallback-dot-license
.PHONY: reuse-apply
