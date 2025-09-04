# Jito Solana RPC Server (Ansible Role)

Production‑ready role to deploy a non‑voting Solana RPC server enhanced with Jito, optional Yellowstone gRPC, Shredstream proxy, and Peregrine gPA cache. Ports are always derived from address variables (`host:port`).

At a Glance
- RPC‑first, non‑voting validator tuned for serving queries.
- Optional Yellowstone gRPC, Shredstream proxy, and Peregrine gPA cache.
- Strict firewall posture; only opens what you opt in to.

Quick Start
1) Minimal inventory (RPC‑only)
```yaml
all:
  hosts:
    my-validator
  vars:
    validator_username: validator
    validator_network: mainnet
    validator_root: /solana
    validator_rpc_address: 0.0.0.0:8899
    validator_enabled_services: [solana-rpc]
```

1) Playbook
```yaml
- hosts: my-validator
  become: true
  roles:
    - role: validator
```

Common Recipes
- Expose RPC publicly:
  ```yaml
  validator_firewall_expose_rpc: true
  validator_rpc_address: 0.0.0.0:8899
  ```
- Enable Yellowstone gRPC and expose its ports:
  ```yaml
  validator_enable_geyser: true
  validator_yellowstone_grpc_address: 0.0.0.0:10000
  validator_yellowstone_prometheus_address: 0.0.0.0:8999
  validator_firewall_expose_yellowstone_grpc: true
  validator_firewall_expose_yellowstone_prometheus: true
  ```
- Use TLS for Yellowstone gRPC:
  ```yaml
  validator_yellowstone_grpc_tls_cert_path: /etc/ssl/certs/yellowstone.crt
  validator_yellowstone_grpc_tls_key_path: /etc/ssl/private/yellowstone.key
  ```
- Enable Peregrine API on localhost:
  ```yaml
  validator_enable_peregrine: true
  validator_peregrine_api_address: 127.0.0.1:1945
  ```
- Tune CPU affinity (Yellowstone):
  ```yaml
  validator_yellowstone_tokio_worker_threads: 8
  validator_yellowstone_tokio_affinity: "0-3,16-19"
  ```

Networking & Ports
- Defaults: deny incoming, allow outgoing. UFW enabled only if inactive; existing allows preserved.
- Always allowed: OpenSSH, `validator_gossip_port` (tcp), `validator_dynamic_port_range` (udp).
- Optional openings (off by default): RPC, Yellowstone gRPC/Prometheus, Peregrine API — opened from their `..._address` values when the corresponding `validator_firewall_expose_*` flag is true.

Migration Notes (address‑only)
- Removed separate `port` variables. Set `..._address` (e.g., `0.0.0.0:8899`) and the role derives ports automatically.
- Updated variables include: `validator_rpc_address`, `validator_peregrine_api_address`. Yellowstone already used addresses.
- Preflight validates that address values include ports when the feature is enabled.

Core

| Variable                 | Default       | Description                                                      |
| ------------------------ | ------------- | ---------------------------------------------------------------- |
| `validator_username`     | `validator`   | Linux user that runs services; must be non‑root.                 |
| `validator_cpu_governor` | `performance` | Target CPU governor (if supported).                              |
| `validator_network`      | `mainnet`     | One of `mainnet`, `testnet`, `devnet`; selects per‑network vars. |

Paths

| Variable                       | Default             | Description          |
| ------------------------------ | ------------------- | -------------------- |
| `validator_root`               | `/solana`           | Root data directory. |
| `validator_ledger_location`    | `/solana/ledger`    | Ledger path.         |
| `validator_accounts_location`  | `/solana/accounts`  | Accounts path.       |
| `validator_snapshots_location` | `/solana/snapshots` | Snapshots path.      |

Environment

| Variable                | Default                    | Description                             |
| ----------------------- | -------------------------- | --------------------------------------- |
| `validator_environment` | `["RUST_LOG=solana=info"]` | Extra environment entries for services. |

Versions / Build

| Variable                        | Default               | Description                              |
| ------------------------------- | --------------------- | ---------------------------------------- |
| `validator_install_rust`        | `true`                | Install Rust toolchain for runtime user. |
| `validator_source_version`      | `v2.3.6-jito`         | Agave/Jito version tag.                  |
| `validator_shredstream_version` | `master`              | Shredstream proxy branch/tag.            |
| `validator_yellowstone_version` | `v9.0.0+solana.2.3.6` | Yellowstone geyser plugin tag.           |
| `validator_peregrine_version`   | `main`                | Peregrine branch/tag.                    |

Identity / Keys

| Variable                     | Default                                        | Description                                      |
| ---------------------------- | ---------------------------------------------- | ------------------------------------------------ |
| `validator_generate_keypair` | `true`                                         | Create identity if missing.                      |
| `validator_public_key`       | `/home/{{ validator_username }}/identity.json` | Identity key path.                               |
| `validator_keypairs`         | `[]`                                           | Extra key files to write; items `{ name, key }`. |

RPC / Node Behavior

| Variable                       | Default | Description                                  |
| ------------------------------ | ------- | -------------------------------------------- |
| `validator_rpc_threads`        | `32`    | RPC worker threads.                          |
| `validator_full_rpc_api`       | `true`  | Enable full RPC API.                         |
| `validator_enable_geyser`      | `false` | Enable Yellowstone Geyser and render config. |
| `validator_x_token`            | ``      | Optional API token used where supported.     |
| `validator_enable_shredstream` | `false` | Build/install Shredstream proxy.             |
| `validator_enable_peregrine`   | `false` | Build/install Peregrine and render config.   |
| `validator_rpc_history`        | `false` | Enable RPC transaction history flags.        |

Indexing

| Variable                       | Default                                         | Description                            |
| ------------------------------ | ----------------------------------------------- | -------------------------------------- |
| `validator_account_index`      | `[program-id, spl-token-owner, spl-token-mint]` | Account indexes to maintain.           |
| `validator_index_exclude_keys` | `[]`                                            | Keys to exclude from indexing.         |
| `validator_index_include_keys` | `[]`                                            | Keys to include regardless of filters. |

Cluster / Validators

| Variable                      | Default | Description                                                     |
| ----------------------------- | ------- | --------------------------------------------------------------- |
| `validator_known_validators`  | `[]`    | Known validator pubkeys.                                        |
| `validator_authorized_voters` | `[]`    | Authorized voters (non‑voting node; provided for completeness). |

Snapshots / Limits

| Variable                                        | Default       | Description                                  |
| ----------------------------------------------- | ------------- | -------------------------------------------- |
| `validator_minimal_snapshot_download_speed`     | `"200000000"` | Minimum snapshot download speed (bytes/sec). |
| `validator_incremental_snapshot_interval_slots` | `"1000"`      | Incremental snapshot interval.               |
| `validator_full_snapshot_interval_slots`        | `"50000"`     | Full snapshot interval.                      |
| `validator_rpc_max_multiple_accounts`           | `"5000"`      | RPC multiple accounts limit.                 |

Networking

| Variable                                | Default                     | Description                                                                               |
| --------------------------------------- | --------------------------- | ----------------------------------------------------------------------------------------- |
| `validator_gossip_port`                 | `"8001"`                    | Gossip TCP port.                                                                          |
| `validator_rpc_address`                 | `"0.0.0.0:8899"`            | RPC bind address with port.                                                               |
| `validator_dynamic_port_range`          | `"8000-10000"`              | Dynamic UDP port range for TPU etc.                                                       |
| `validator_wal_recovery_mode`           | `skip_any_corrupted_record` | WAL recovery behavior.                                                                    |
| `validator_limit_ledger_size`           | ``                          | Empty uses `--limit-ledger-size` (auto); set value to pass `--limit-ledger-size <value>`. |
| `validator_accounts_db_cache_limit`     | `800000`                    | MB for accounts DB cache.                                                                 |
| `validator_accounts_index_memory_limit` | `150000`                    | MB for accounts index memory.                                                             |
| `validator_gossip_host`                 | ``                          | Optional explicit gossip host; otherwise uses `validator_entrypoints`.                    |
| `validator_entrypoints`                 | varies by network           | Entry points (host:port) list; set in `vars/<network>.yml`.                               |

Bigtable

| Variable                            | Default | Description                         |
| ----------------------------------- | ------- | ----------------------------------- |
| `validator_bigtable_enabled`        | `false` | Enable RPC Bigtable ledger storage. |
| `validator_bigtable_upload_enabled` | `false` | Enable Bigtable ledger upload.      |

Services

| Variable                      | Default        | Description               |
| ----------------------------- | -------------- | ------------------------- |
| `validator_enabled_services`  | `[solana-rpc]` | User services to enable.  |
| `validator_disabled_services` | `[]`           | User services to disable. |

Sysctl Optimisations

| Variable                         | Default | Description                                                |
| -------------------------------- | ------- | ---------------------------------------------------------- |
| `validator_sysctl_optimisations` | map     | fd limits, TCP buffers, watchdog, vm.max_map_count tuning. |

Repository URLs

| Variable                         | Default                                              | Description         |
| -------------------------------- | ---------------------------------------------------- | ------------------- |
| `validator_jito_solana_repo_url` | `https://github.com/jito-foundation/jito-solana.git` | Agave/Jito source.  |
| `validator_yellowstone_repo_url` | `https://github.com/rpcpool/yellowstone-grpc.git`    | Yellowstone source. |
| `validator_shredstream_repo_url` | `https://github.com/jito-labs/shredstream-proxy.git` | Shredstream source. |
| `validator_peregrine_repo_url`   | `https://github.com/thyra-labs/peregrine.git`        | Peregrine source.   |

Shredstream

| Variable                                  | Default                 | Description                                    |
| ----------------------------------------- | ----------------------- | ---------------------------------------------- |
| `validator_shredstream_block_engine_url`  | ``                      | Jito Block Engine URL.                         |
| `validator_shredstream_regions`           | `"amsterdam,frankfurt"` | Proxy regions.                                 |
| `validator_shredstream_udp_port`          | `"20000"`               | UDP bind port for shreds (0 allows ephemeral). |
| `validator_shredstream_grpc_service_port` | ``                      | Optional proxy gRPC service port.              |
| `validator_shredstream_auth_keypair`      | ``                      | JSON array key material for Block Engine auth. |
| `validator_shredstream_auth_keypair_b64`  | ``                      | Base64 of JSON array key.                      |
| `validator_shredstream_auth_keypair_b58`  | ``                      | Base58 64‑byte secret key (takes precedence).  |

Firewall Exposure Toggles

| Variable                                           | Default | Description                                                                              |
| -------------------------------------------------- | ------- | ---------------------------------------------------------------------------------------- |
| `validator_firewall_expose_rpc`                    | `false` | Allow port parsed from `validator_rpc_address`.                                          |
| `validator_firewall_expose_yellowstone_grpc`       | `false` | Allow port parsed from `validator_yellowstone_grpc_address` (when geyser enabled).       |
| `validator_firewall_expose_yellowstone_prometheus` | `false` | Allow port parsed from `validator_yellowstone_prometheus_address` (when geyser enabled). |
| `validator_firewall_expose_peregrine_api`          | `false` | Allow port parsed from `validator_peregrine_api_address` (when peregrine enabled).       |

Yellowstone gRPC / Prometheus

| Variable                                                      | Default                                             | Description                                                  |
| ------------------------------------------------------------- | --------------------------------------------------- | ------------------------------------------------------------ |
| `validator_yellowstone_libpath`                               | `"../target/release/libyellowstone_grpc_geyser.so"` | Path to geyser plugin `.so`.                                 |
| `validator_yellowstone_log_level`                             | `"info"`                                            | Yellowstone log level.                                       |
| `validator_yellowstone_tokio_worker_threads`                  | `8`                                                 | Tokio worker threads.                                        |
| `validator_yellowstone_tokio_affinity`                        | `"0-1,12-13"`                                       | CPU affinity mask string.                                    |
| `validator_yellowstone_grpc_address`                          | `"0.0.0.0:10000"`                                   | gRPC bind address with port.                                 |
| `validator_yellowstone_grpc_tls_cert_path`                    | ``                                                  | TLS cert path (requires key too or both empty).              |
| `validator_yellowstone_grpc_tls_key_path`                     | ``                                                  | TLS key path (requires cert too or both empty).              |
| `validator_yellowstone_grpc_compression_accept`               | `[gzip, zstd]`                                      | Accepted gRPC compression types.                             |
| `validator_yellowstone_grpc_compression_send`                 | `[gzip, zstd]`                                      | Enabled gRPC compression on responses.                       |
| `validator_yellowstone_server_http2_adaptive_window`          | `null`                                              | HTTP/2 adaptive window.                                      |
| `validator_yellowstone_server_http2_keepalive_interval`       | `null`                                              | gRPC keepalive interval.                                     |
| `validator_yellowstone_server_http2_keepalive_timeout`        | `null`                                              | gRPC keepalive timeout.                                      |
| `validator_yellowstone_server_initial_connection_window_size` | `null`                                              | Connection window size.                                      |
| `validator_yellowstone_server_initial_stream_window_size`     | `null`                                              | Stream window size.                                          |
| `validator_yellowstone_grpc_max_decoding_message_size`        | `"4_194_304"`                                       | Max decoding message size.                                   |
| `validator_yellowstone_grpc_snapshot_plugin_channel_capacity` | `null`                                              | Snapshot plugin channel capacity.                            |
| `validator_yellowstone_grpc_snapshot_client_channel_capacity` | `"50_000_000"`                                      | Snapshot client channel capacity.                            |
| `validator_yellowstone_grpc_channel_capacity`                 | `"100_000"`                                         | General channel capacity.                                    |
| `validator_yellowstone_grpc_unary_concurrency_limit`          | `100`                                               | Unary RPC concurrency limit.                                 |
| `validator_yellowstone_grpc_unary_disabled`                   | `false`                                             | Disable unary RPC endpoints.                                 |
| `validator_yellowstone_grpc_replay_stored_slots`              | `0`                                                 | Number of stored slots to replay.                            |
| `validator_yellowstone_grpc_filter_name_size_limit`           | `128`                                               | Max filter name size.                                        |
| `validator_yellowstone_grpc_filter_names_size_limit`          | `4096`                                              | Combined filter names size limit.                            |
| `validator_yellowstone_grpc_filter_names_cleanup_interval`    | `"1s"`                                              | Cleanup interval for filter names.                           |
| `validator_yellowstone_grpc_filters`                          | `{}`                                                | Filters object per Yellowstone schema; `{}` means no limits. |
| `validator_yellowstone_prometheus_address`                    | `"0.0.0.0:8999"`                                    | Prometheus metrics bind address with port.                   |

Peregrine (gPA Cache)

| Variable                                      | Default                    | Description                                               |
| --------------------------------------------- | -------------------------- | --------------------------------------------------------- |
| `validator_peregrine_grpc_enabled`            | `true`                     | Whether to connect to Yellowstone gRPC.                   |
| `validator_peregrine_grpc_endpoint`           | `"http://127.0.0.1:10000"` | Yellowstone endpoint URL.                                 |
| `validator_peregrine_grpc_use_tls`            | `false`                    | Enable TLS for gRPC to Yellowstone.                       |
| `validator_peregrine_grpc_connection_timeout` | `"10s"`                    | gRPC connection timeout.                                  |
| `validator_peregrine_grpc_request_timeout`    | `"30s"`                    | gRPC request timeout.                                     |
| `validator_peregrine_grpc_retry_attempts`     | `3`                        | Retry attempts for gRPC.                                  |
| `validator_peregrine_grpc_retry_delay`        | `"1s"`                     | Retry delay for gRPC.                                     |
| `validator_peregrine_rpc_endpoint`            | `"http://127.0.0.1:8899"`  | RPC endpoint to the validator.                            |
| `validator_peregrine_rpc_connection_timeout`  | `"10s"`                    | RPC connection timeout.                                   |
| `validator_peregrine_rpc_request_timeout`     | `"10m"`                    | RPC request timeout.                                      |
| `validator_peregrine_rpc_max_connections`     | `100`                      | Max HTTP client connections.                              |
| `validator_peregrine_rpc_max_idle_per_host`   | `10`                       | Idle per host.                                            |
| `validator_peregrine_rpc_keep_alive_timeout`  | `"60s"`                    | HTTP keep‑alive timeout.                                  |
| `validator_peregrine_api_address`             | `"0.0.0.0:1945"`           | HTTP API bind address with port.                          |
| `validator_peregrine_api_max_connections`     | `128`                      | Max simultaneous HTTP connections.                        |
| `validator_peregrine_api_request_timeout`     | `"30s"`                    | API request timeout.                                      |
| `validator_peregrine_perf_worker_threads`     | `16`                       | Worker thread count.                                      |
| `validator_peregrine_perf_blocking_threads`   | `64`                       | Blocking thread count.                                    |
| `validator_peregrine_perf_buffer_size`        | `65536`                    | Buffer size.                                              |
| `validator_peregrine_perf_batch_size`         | `100`                      | Batch size.                                               |
| `validator_peregrine_perf_enable_compression` | `true`                     | Enable compression.                                       |
| `validator_peregrine_programs`                | `[]`                       | Programs/filters list; copied to JSON in rendered config. |

Optional Validator Flags (advanced)

| Variable                                    | Default | Description                           |
| ------------------------------------------- | ------- | ------------------------------------- |
| `validator_snapshot_compression`            | ``      | Snapshot archive format.              |
| `validator_rpc_faucet_address`              | ``      | RPC faucet address.                   |
| `validator_expected_shred_version`          | ``      | Expected shred version.               |
| `validator_expected_bank_hash`              | ``      | Expected bank hash.                   |
| `validator_wait_for_supermajority`          | ``      | Wait for supermajority slot.          |
| `validator_hard_fork`                       | ``      | Hard fork slot.                       |
| `validator_accounts_shrink_path`            | ``      | Account shrink path.                  |
| `validator_tip_payment_program_pubkey`      | ``      | Tip payment program pubkey.           |
| `validator_tip_distribution_program_pubkey` | ``      | Tip distribution program pubkey.      |
| `validator_merkle_root_upload_authority`    | ``      | Merkle root upload authority.         |
| `validator_block_engine_url`                | ``      | Block Engine URL (Agave integration). |
| `validator_relayer_url`                     | ``      | Relayer URL (Agave integration).      |
| `validator_shred_receiver_address`          | ``      | Shred receiver address (host:port).   |

Per‑Network Variables (vars/)

| File               | Variables                                                                                                     |
| ------------------ | ------------------------------------------------------------------------------------------------------------- |
| `vars/mainnet.yml` | `validator_genesis_hash`, `validator_entrypoints`, `validator_known_validators`, tip program/pubkeys.         |
| `vars/testnet.yml` | `validator_genesis_hash`, `validator_entrypoints`, `validator_known_validators`, testnet tip program/pubkeys. |
| `vars/devnet.yml`  | `validator_genesis_hash`, `validator_entrypoints`; shredstream disabled by default.                           |

License

MIT

Troubleshooting
- Build failures: ensure the target has network access to GitHub/crates.io and enough disk space; re‑run with `-vvv` for more logs.
- systemd assertion: the role requires systemd; ensure the target is Debian/Ubuntu with systemd as `ansible_service_mgr`.
- Firewall rules: run `sudo ufw status numbered` on the target to verify allows; existing allows are preserved.
- Address validation: preflight enforces `host:port` format; check `validator_*_address` values when you see assertion errors.
- Yellowstone TLS: both cert and key must be set; leaving one empty will fail preflight.

Security Notes
- Bind to localhost for admin‑only endpoints (e.g., `validator_peregrine_api_address: 127.0.0.1:1945`).
- Only set `validator_firewall_expose_*` flags for ports you intend to expose publicly.
- Use TLS for Yellowstone gRPC in multi‑tenant or untrusted networks; keep keys readable only by the runtime user.
- Keep `validator_x_token` secret; it’s templated into configs when provided.

Validate Locally
- Syntax check: `ansible-playbook --syntax-check -i localhost, -c local playbook_syntax.yml`.
- Dry run (target host): `ansible-playbook -C -i <inventory> -l <host> <playbook>.yml`.
