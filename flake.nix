# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

{
  description = "Homelab infrastructure development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-kubectl-directpv.url = "github:Ajpantuso/nix-kubectl-directpv";
  };

  outputs = { self, nixpkgs, flake-utils, nix-kubectl-directpv }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bash
            coreutils
            findutils
            fluxcd
            git
            gnumake
            kubectl
            kustomize
            nix-kubectl-directpv.packages.${system}.default
            podman
            pre-commit
            reuse
          ];

          shellHook = ''
            export PROJECT_ROOT="$(git rev-parse --show-toplevel)";

              # Check if 'core' context exists, if not create it
            if ! kubectl config get-contexts | grep -q "core"; then
              kubectl config set-cluster core --server=https://core.ajphome.com:6443 --insecure-skip-tls-verify=true
              kubectl config set-context core --cluster=core --user=ajpantuso@gmail.com
            fi

            # Test connectivity to the cluster
            if kubectl cluster-info --context=core &>/dev/null; then
              kubectl config use-context core
            else
              echo "Warning: Could not connect to core cluster at https://core.ajphome.com:6443"
            fi
          '';
        };
      });
}
