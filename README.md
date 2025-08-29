# Ansible Role: Jito Solana Validator

This role installs and configures a Jito-enhanced Solana validator (RPC) on a Linux host. It:

- Builds `jito-solana` at a specified tag (HTTPS by default) and installs binaries into a release directory.
- Ensures `~/.local/share/solana/install/active_release` points to the current release.
- Optionally builds and configures Yellowstone gRPC and Jito Shredstream proxy (disabled by default).
- Sets up systemd units and operational defaults suitable for mainnet/testnet/devnet.

## Requirements

- Linux host with systemd.
- A non-root user to run the validator (e.g. `validator`).
- Network access to GitHub and crates.io for builds.

## Role Variables (highlights)

- `validator_username` (string): System user that owns processes and files.
- `validator_network` (string): One of `mainnet`, `testnet`, `devnet`.
- `validator_root` (path): Base directory for validator state and keys.
- `validator_ledger_location` (path): Ledger directory.
- `validator_accounts_location` (path): Accounts directory.
- `validator_source_version` (string): jito-solana version tag, e.g. `v2.3.6-jito`.
- `validator_enable_geyser` (bool, default false): Build and enable Yellowstone gRPC.
- `validator_enable_shredstream` (bool, default false): Build and enable Jito Shredstream proxy.
- `validator_enable_peregrine` (bool, default false): Build and enable Peregrine gPA cache.
- `validator_environment` (list): Extra environment variables for the service.
- `validator_git_use_ssh` (bool, default false): Use SSH for Git operations.
- `jito_solana_repo_url` (string): Defaults to `https://github.com/jito-foundation/jito-solana.git`.
- `yellowstone_repo_url` (string): Defaults to `https://github.com/rpcpool/yellowstone-grpc.git`.
- `shredstream_repo_url` (string, optional): Set to your fork if enabling shredstream.
- `peregrine_repo_url` (string, optional): Set to your fork if enabling Peregrine.

Network presets with sane defaults live under `vars/`.

## Example Playbook

```yaml
- hosts: validators
  become: true
  roles:
    - role: validator
      vars:
        validator_username: validator
        validator_network: mainnet
        validator_root: "/home/validator/validator"
        validator_ledger_location: "/home/validator/ledger"
        validator_accounts_location: "/home/validator/accounts"
        validator_source_version: "v2.3.6-jito"
        validator_enable_geyser: false
        validator_enable_shredstream: false
        validator_git_use_ssh: false
        # Optional repos when enabling components
        # shredstream_repo_url: https://github.com/yourorg/shredstream-proxy.git
        # peregrine_repo_url: https://github.com/yourorg/peregrine.git
```

## Notes

- The role explicitly updates `~/.local/share/solana/install/active_release` to point to the current release directory after building.
- Secrets and API tokens are expected to be provided via inventory/group vars or Ansible Vault. No secrets are committed in this repository.
 - Network endpoints like block engine, relayer, and shred receiver are blank by default; set them if required by your provider.

## Publishing

This repository is designed to be public. To publish:

```bash
git remote add origin git@github.com:<org>/ansible-role-jito-solana-validator.git
git push -u origin main
```

Then, in any consumer repo using a submodule, update the submodule remote URL to the public GitHub URL and commit the change.
