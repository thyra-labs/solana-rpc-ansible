#!/usr/bin/env bash
set -euo pipefail

export RUST_LOG=${RUST_LOG:-info}

"/home/{{ validator_username }}/shredstream-proxy/target/release/jito-shredstream-proxy" shredstream \
  --block-engine-url {{ validator_shredstream_block_engine_url }} \
  --auth-keypair jito-blockengine-keypair.json \
  --desired-regions {{ validator_shredstream_regions }} \
  --dest-ip-ports 127.0.0.1:8000
