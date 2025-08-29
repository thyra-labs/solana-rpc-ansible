#!/usr/bin/env bash
set -euo pipefail
trap 'echo "Error on line $LINENO, exit code $?" >&2' ERR

# Remove any zero-byte snapshots
find "{{ validator_ledger_location }}" -name 'snapshot-*' -size 0 -print -exec rm {} \; || true

# Build command + args
BINARY="~/.local/share/solana/install/releases/{{ validator_source_version }}/bin/agave-validator"
ARGS=()

# Identity & networking
ARGS+=(--identity "{{ validator_public_key }}")
{% if validator_gossip_host is defined and validator_gossip_host|length > 0 %}
ARGS+=(--gossip-host "{{ validator_gossip_host }}")
{% else %}
{% for ep in validator_entrypoints %}
ARGS+=(--entrypoint "{{ ep }}")
{% endfor %}
{% endif %}
{% if validator_gossip_port is defined and validator_gossip_port|length > 0 %}
ARGS+=(--gossip-port "{{ validator_gossip_port }}")
{% endif %}

# Ledger, accounts, snapshots
ARGS+=(--ledger "{{ validator_ledger_location }}")
{% if validator_accounts_location is defined %}
ARGS+=(--accounts "{{ validator_accounts_location }}")
{% endif %}
{% if validator_snapshots_location is defined %}
ARGS+=(--snapshots "{{ validator_snapshots_location }}")
{% endif %}
{% if validator_snapshot_compression is defined %}
ARGS+=(--snapshot-archive-format "{{ validator_snapshot_compression }}")
{% endif %}

# Core flags
ARGS+=(
  --log -
  --rpc-port "{{ validator_rpc_port }}"
  --rpc-bind-address "{{ validator_rpc_bind_address }}"
  --dynamic-port-range "{{ validator_dynamic_port_range }}"
  --wal-recovery-mode "{{ validator_wal_recovery_mode }}"
  --limit-ledger-size {{ validator_limit_ledger_size }}
  --private-rpc
  --no-genesis-fetch
  --no-voting
  --skip-startup-ledger-verification
  --skip-seed-phrase-validation
  --tpu-enable-udp
  --no-poh-speed-test
  --skip-poh-verify
  --no-os-network-stats-reporting
  --no-os-memory-stats-reporting
  --no-os-cpu-stats-reporting
  --disable-banking-trace
)

# Tip-payment & block-engine integration
{% if validator_tip_payment_program_pubkey is defined and
      validator_tip_distribution_program_pubkey is defined and
      validator_merkle_root_upload_authority is defined and
      validator_block_engine_url is defined and
      validator_relayer_url is defined and
      validator_shred_receiver_address is defined %}
ARGS+=(
  --tip-payment-program-pubkey "{{ validator_tip_payment_program_pubkey }}"
  --tip-distribution-program-pubkey "{{ validator_tip_distribution_program_pubkey }}"
  --merkle-root-upload-authority "{{ validator_merkle_root_upload_authority }}"
  --commission-bps 0
  --relayer-url "{{ validator_relayer_url }}"
  --block-engine-url "{{ validator_block_engine_url }}"
  --shred-receiver-address "{{ validator_shred_receiver_address }}"
)
{% endif %}

# Geyser plugin
{% if validator_enable_geyser %}
ARGS+=(--geyser-plugin-config "/home/{{ validator_username }}/yellowstone-grpc/yellowstone-grpc-geyser/config.json")
{% endif %}

# Optional tuning
{% if validator_minimal_snapshot_download_speed is defined %}
ARGS+=(--minimal-snapshot-download-speed "{{ validator_minimal_snapshot_download_speed }}")
{% endif %}
{% if validator_full_rpc_api %}
ARGS+=(--full-rpc-api)
{% endif %}
{% if validator_known_validators|length > 0 %}
ARGS+=(--only-known-rpc)
{% endif %}
{% if validator_rpc_history %}
ARGS+=(
  --enable-extended-tx-metadata-storage
  --enable-rpc-transaction-history
)
{% endif %}
{% if validator_accounts_index_memory_limit is defined and validator_accounts_index_memory_limit > 0 %}
ARGS+=(--accounts-index-memory-limit-mb={{validator_accounts_index_memory_limit}})
{% endif %}
{% if validator_accounts_db_cache_limit is defined and validator_accounts_db_cache_limit > 0 %}
ARGS+=(--accounts-db-cache-limit-mb={{validator_accounts_db_cache_limit}})
{% endif %}

# Indexing & Bigtable
ARGS+=(--account-index "{{ validator_account_index | join(' ') }}")
ARGS+=(--expected-genesis-hash "{{ validator_genesis_hash }}")
{% if validator_rpc_threads is defined and validator_rpc_threads > 0 %}
ARGS+=(--rpc-threads "{{ validator_rpc_threads }}")
{% endif %}
{% if validator_bigtable_enabled %}
ARGS+=(--enable-rpc-bigtable-ledger-storage)
{% endif %}
{% if validator_bigtable_upload_enabled %}
ARGS+=(--enable-bigtable-ledger-upload)
{% endif %}
{% if validator_rpc_faucet_address is defined and validator_rpc_faucet_address|length > 0 %}
ARGS+=(--rpc-faucet-address "{{ validator_rpc_faucet_address }}")
{% endif %}

# Snapshot intervals & RPC limits
{% if validator_incremental_snapshot_interval_slots is defined %}
ARGS+=(--incremental-snapshot-interval-slots "{{ validator_incremental_snapshot_interval_slots }}")
{% endif %}
{% if validator_full_snapshot_interval_slots is defined %}
ARGS+=(--full-snapshot-interval-slots "{{ validator_full_snapshot_interval_slots }}")
{% endif %}
{% if validator_rpc_max_multiple_accounts is defined %}
ARGS+=(--rpc-max-multiple-accounts "{{ validator_rpc_max_multiple_accounts }}")
{% endif %}

# Expected hashes & forks
{% if validator_expected_shred_version is defined and validator_expected_shred_version|length > 0 %}
ARGS+=(--expected-shred-version "{{ validator_expected_shred_version }}")
{% endif %}
{% if validator_expected_bank_hash is defined and validator_expected_bank_hash|length > 0 %}
ARGS+=(--expected-bank-hash "{{ validator_expected_bank_hash }}")
{% endif %}
{% if validator_wait_for_supermajority is defined and validator_wait_for_supermajority|length > 0 %}
ARGS+=(--wait-for-supermajority "{{ validator_wait_for_supermajority }}")
{% endif %}
{% if validator_hard_fork is defined and validator_hard_fork|length > 0 %}
ARGS+=(--hard-fork "{{ validator_hard_fork }}")
{% endif %}
{% if validator_accounts_shrink_path is defined and validator_accounts_shrink_path|length > 0 %}
ARGS+=(--account-shrink-path "{{ validator_accounts_shrink_path }}")
{% endif %}

# Exclude keys, voters, known validators
{% for key in validator_index_exclude_keys %}
ARGS+=(--account-index-exclude-key "{{ key }}")
{% endfor %}
{% for key in validator_index_include_keys %}
ARGS+=(--account-index-include-key "{{ key }}")
{% endfor %}
{% for voter in validator_authorized_voters %}
ARGS+=(--authorized-voter "{{ voter }}")
{% endfor %}
{% for kv in validator_known_validators %}
ARGS+=(--known-validator "{{ kv }}")
{% endfor %}

exec "${BINARY}" "${ARGS[@]}"
