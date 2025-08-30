# Jito Solana Validator (Ansible Role)

Production‑ready role to deploy a Jito‑enhanced Solana RPC validator with optional Yellowstone gRPC, Jito Shredstream, and Peregrine gPA cache. Safe defaults, clear variables, and systemd user services.

What this role does
- Builds and installs `jito-solana` at a pinned tag.
- Optionally builds/configures Yellowstone gRPC, Shredstream proxy, and Peregrine.
- Installs user services; enables only what you list in `validator_enabled_services`.
- Configures UFW: preserves existing allows, denies other incoming, opens only required ports.

Requirements
- Ubuntu/Debian with systemd
- Non‑root runtime user (e.g. `validator`)
- Network access to GitHub/crates.io

Quick start
1) Inventory
```yaml
all:
  hosts:
    my-validator
  vars:
    validator_username: validator
    validator_network: mainnet
    validator_root: /solana
    validator_ledger_location: /solana/ledger
    validator_accounts_location: /solana/accounts
    validator_source_version: v2.3.6-jito
    validator_enabled_services: [solana-rpc]
```

2) Playbook
```yaml
- hosts: my-validator
  become: true
  roles:
    - role: validator
```

Firewall
- Defaults: deny incoming, allow outgoing; existing allow rules (e.g. 80/443) are preserved.
- Allows: OpenSSH, `{{ validator_gossip_port }}`/tcp, `{{ validator_dynamic_port_range }}`/udp.
- Shredstream: opens `{{ validator_shredstream_udp_port }}`/udp only when enabled.
- UFW enabled only if inactive.

Optional exposures (closed by default)
- `firewall_expose_rpc`: when true, allows `{{ validator_rpc_port }}`/tcp from anywhere.
- `firewall_expose_yellowstone_grpc`: when true and geyser enabled, allows the port parsed from `yellowstone_grpc_address` (default `10000`)/tcp.
- `firewall_expose_yellowstone_prometheus`: when true and geyser enabled, allows the port parsed from `yellowstone_prometheus_address` (default `8999`)/tcp.
- `firewall_expose_peregrine_api`: when true and peregrine enabled, allows `{{ peregrine_api_port }}`/tcp.

Keys and identity
- Auto‑generate identity when `validator_generate_keypair: true`.
- To provide your own keys:
```yaml
validator_generate_keypair: false
validator_keypairs:
  - name: identity
    key: |
      [1,2,3, ... 64 bytes ...]
  - name: vote
    key: |
      [9,9,9, ...]
validator_public_key: "/home/{{ validator_username }}/identity.json"
```

Yellowstone gRPC
- Enable: `validator_enable_geyser: true`.
- Config path: `/home/{{ validator_username }}/yellowstone-grpc/yellowstone-grpc-geyser/config.json`.
- Token: `validator_x_token` is optional (renders `null` when empty).
- TLS: set both `yellowstone_grpc_tls_cert_path` and `yellowstone_grpc_tls_key_path`; otherwise `tls_config` is `null`.
- Filters: set `yellowstone_grpc_filters` to enforce limits; leave `{}` for no limits. Matches Yellowstone's `filters` schema.

Service management
- The role installs unit files and enables services you list in:
  - `validator_enabled_services` and `validator_disabled_services`.
- Default enabled: `[solana-rpc]`.
- Valid service names:
  - `solana-rpc` (validator RPC)
  - `shredstream-proxy` (Jito Shredstream)
  - `peregrine` (gPA cache)
Note: Do not list a service in both enabled and disabled; the role validates and errors on overlap or unknown names.

Peregrine gPA Cache
- Enable: `validator_enable_peregrine: true`.
- Runs binary: `/home/{{ validator_username }}/peregrine/target/release/peregrine run`.
- Token: uses `validator_x_token` (renders `null` when empty).
- Filters/programs: override in YAML via `peregrine_programs`. If empty, built‑in defaults are used.
```yaml
peregrine_programs:
  - program_id: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
    filters:
      - memcmp: { offset: 0, bytes: [1] }
```

Shredstream proxy
- Enable: `validator_enable_shredstream: true` and set:
```yaml
shredstream_repo_url: https://github.com/yourorg/shredstream-proxy.git
validator_shredstream_block_engine_url: https://frankfurt.mainnet.block-engine.jito.wtf
validator_shredstream_regions: "amsterdam,frankfurt"
# Provide one (priority b58 > b64 > JSON array):
validator_shredstream_auth_keypair_b58: "<base58 64‑byte secret>"
# OR
validator_shredstream_auth_keypair_b64: "<base64 of JSON array>"
# OR
validator_shredstream_auth_keypair: |
  [1,2,3, ...]
```
- The role writes `jito-blockengine-keypair.json` and installs `run.sh` accordingly.

CPU affinity (Yellowstone)
- Match `yellowstone_tokio_worker_threads` to the number of CPUs in `yellowstone_tokio_affinity`.
- Prefer CPUs from the same NUMA node; avoid CPU0/IRQ hotspots when possible.

Tips and troubleshooting
- Bigtable: when `validator_bigtable_enabled: true`, credentials are templated to `/home/{{ validator_username }}/bigtable.json` and referenced by `GOOGLE_APPLICATION_CREDENTIALS`.
- Build/runtime issues: ensure Rust toolchain installs for the user, and your distro packages are present.
- Shredstream base58: provide the full 64‑byte secret key (secret+public) when using base58.

Contributing
PRs welcome. Keep changes focused and include rationale.

License
MIT
