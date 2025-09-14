<!--
SPDX-FileCopyrightText: 2025 NONE

SPDX-License-Identifier: Unlicense
-->

# TODO

- Manage CA and SSH certs with Vault
- Integrate cert-manager with Vault as external-issuer
  - https://cert-manager.io/docs/configuration/vault/
- Mount SSD on core server
- Change PV hostpaths to mounted SSD (half done)
- Embed coreos host ignition in PXE img and add extra steps to unique ignition files

## References

- https://github.com/charmbracelet/soft-serve
- https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-install
- https://developer.hashicorp.com/vault/tutorials/secrets-management/pki-engine`
- https://cert-manager.io/docs/configuration/vault/
- https://github.com/thecmdrunner/vfio-gpu-configs
