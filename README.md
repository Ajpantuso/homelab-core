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
- Look into migrating to https://github.com/minio/directpv
- New cluster to run Minio for backups and general object storage

## References

- https://github.com/charmbracelet/soft-serve
- https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-install
- https://developer.hashicorp.com/vault/tutorials/secrets-management/pki-engine`
- https://cert-manager.io/docs/configuration/vault/
- https://github.com/thecmdrunner/vfio-gpu-configs
