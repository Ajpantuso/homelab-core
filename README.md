# TODO

- Add certificates for:
  - MeshCentral
  - pxe
  - soft-serve
    - mount config.yaml with TLS paths and `https` url
    - mount tls key and server cert at paths
- Deploy Vault
- Manage CA and SSH certs with Vault
- Integrate cert-manager with Vault as external-issuer
- Mount SSD on core server
- Change PV hostpaths to mounted SSD

## References

- https://github.com/charmbracelet/soft-serve
- https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-install
- https://developer.hashicorp.com/vault/tutorials/secrets-management/pki-engine`
- https://cert-manager.io/docs/configuration/vault/
