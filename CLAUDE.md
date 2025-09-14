<!--
SPDX-FileCopyrightText: 2025 NONE

SPDX-License-Identifier: Unlicense
-->

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository manages a complete homelab infrastructure using a GitOps approach with Flux CD on a k0s Kubernetes cluster. The infrastructure runs on Fedora CoreOS with declarative configuration through Butane/Ignition files.

## Architecture

### Core Components

- **k0s Kubernetes Cluster**: Lightweight Kubernetes distribution managed via k0sctl
- **Flux CD**: GitOps continuous deployment using HelmReleases and Kustomizations
- **Fedora CoreOS**: Immutable operating system with configuration via Ignition files
- **PXE Boot Infrastructure**: Network boot setup for bare metal and virtual machines
- **Certificate Management**: cert-manager with CA-based certificate issuance
- **DNS Management**: external-dns with OpnSense webhook integration
- **Storage**: OpenEBS for persistent volumes with MetalLB for load balancing

### Directory Structure

- `flux/`: Flux CD configurations (HelmReleases, GitRepositories, Kustomizations)
- `ignition/`: Butane files (.bu) for Fedora CoreOS configuration
- `overlays/`: File system overlays for CoreOS images
- `ansible/`: Ansible playbooks for host configuration and k0s management
- `k0s/`: k0s cluster configuration and patches
- `*/base/` and `*/overlays/`: Kustomize structure for Kubernetes manifests
- `kickstart/`: PXE kickstart templates for hypervisor installation

### Key Configuration Files

- `Makefile`: All automation commands and build processes
- `flake.nix`: Nix development environment with required tools
- `k0s/k0s.Cluster.yaml`: Base k0s cluster configuration
- `flux/kustomization.yaml`: Root Flux configuration manifest

## Common Commands

### Environment Setup
```bash
# Enter Nix development shell (provides all required tools)
nix develop

# Generate k0sctl configuration from templates
make generate-config

# Generate base k0s configuration
make generate-k0s
```

### Cluster Management
```bash
# Apply k0s cluster configuration
make k0s-apply

# Reset entire k0s cluster
make k0s-reset

# Generate and install kubeconfig
make k0s-config

# Apply Flux configuration to cluster
make flux-apply
```

### CoreOS Image Generation
```bash
# Generate all CoreOS PXE boot artifacts
make coreos-generate-pxe

# Generate hypervisor PXE artifacts
make hypervisor-generate-pxe

# Generate ignition files for different node types
make core-generate-ignition
make k0s-generate-ignition
make pki-generate-ignition

# Generate bootable CoreOS ISO
make coreos-generate-iso
```

### Infrastructure Deployment
```bash
# Apply PXE configuration to core server
make apply-pxe

# Install CoreOS on ARM device
make core-arm-install

# Clean all generated artifacts
make clean
```

## Development Patterns

### Flux CD GitOps Workflow
1. All Kubernetes resources are defined declaratively in `flux/` directory
2. HelmReleases define application deployments with version pinning (e.g., `1.18.*`)
3. Kustomizations reference GitRepositories for source-controlled manifests
4. Changes to this repository automatically trigger deployments via Flux

### Version Management
- Helm chart versions use wildcard patterns (e.g., `1.19.*`) for automatic patch updates
- Container images are pinned to specific tags in HelmRelease values
- CoreOS version is pinned in Makefile variables (`COREOS_VERSION`)

### Configuration Management
- Butane files (`.bu`) generate Ignition files for CoreOS configuration
- File system overlays in `overlays/` are embedded into CoreOS images
- Ansible playbooks handle post-boot configuration and k0s cluster management
- Environment variables are configured via `.env` file (git-ignored)

### Infrastructure as Code Structure
- Each service follows kustomize base/overlay pattern
- Base configurations in `*/base/` directories
- Environment-specific overrides in `*/overlays/dev/`
- Kubernetes manifests are generated and never hand-edited

## Important Notes

- KUBECONFIG is automatically set to `.cache/.kube/config` in the Nix shell
- All generated artifacts are placed in `.cache/` directory
- Container engine defaults to `docker` but can be overridden with `CONTAINER_ENGINE`
- SSH keys and certificates are managed through overlays and Ignition files
- The cluster uses custom CA certificates managed by cert-manager
