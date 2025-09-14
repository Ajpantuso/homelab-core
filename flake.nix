{
  description = "Homelab infrastructure development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        pykickstart = pkgs.python3Packages.buildPythonPackage rec {
          pname = "pykickstart";
          version = "3.48";
          pyproject = true;

          src = pkgs.fetchPypi {
            inherit pname version;
            hash = "sha256-ycj22sf2RV0QHQFVLSZfEm3rSUfR4WtdhTpijK5x+Ek=";
          };

          build-system = with pkgs.python3Packages; [
            setuptools
          ];

          dependencies = with pkgs.python3Packages; [
            requests
            six
          ];

          doCheck = false; # Skip tests for now

          meta = with pkgs.lib; {
            description = "Python library for manipulating kickstart files";
            homepage = "https://github.com/pykickstart/pykickstart";
            license = licenses.gpl2Plus;
          };
        };

        coreos-installer = pkgs.rustPlatform.buildRustPackage rec {
          pname = "coreos-installer";
          version = "0.24.0";

          src = pkgs.fetchCrate {
            inherit pname version;
            hash = "sha256-UPNP81cR4Fihm/w/1WOehSEQayZBm2oIqlZo0OlBaw0=";
          };

          cargoHash = "sha256-qGgFQy9tIwpG/+2YCq8CZbSmix+Heq1iOKrGmfh7QeM=";

          nativeBuildInputs = with pkgs; [
            pkg-config
          ];

          buildInputs = with pkgs; [
            openssl
            zstd
            gnupg
          ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            pkgs.darwin.apple_sdk.frameworks.Security
          ];

          doCheck = false;

          meta = with pkgs.lib; {
            description = "Installer for CoreOS disk images";
            homepage = "https://github.com/coreos/coreos-installer";
            license = licenses.asl20;
            mainProgram = "coreos-installer";
          };
        };

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            ansible
            bash
            butane
            coreos-installer
            coreutils
            findutils
            git
            gnumake
            k0sctl
            kubectl
            kustomize
            mo
            podman
            pre-commit
            pykickstart
            python3
            reuse
          ];

          shellHook = ''
            export PROJECT_ROOT="$(git rev-parse --show-toplevel)";
            export CACHE_DIR="$PROJECT_ROOT/.cache";
            mkdir -p "$CACHE_DIR";
            export KUBECONFIG="$CACHE_DIR/.kube/config";

            echo "Homelab infrastructure development environment loaded"
            echo "Project root: $PROJECT_ROOT"
          '';
        };
      });
}
