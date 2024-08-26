#!/bin/bash

ARWEAVE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

source $ARWEAVE_DIR/testnet/testnet_nodes.sh

mkdir -p $ARWEAVE_DIR/arweave-build/mainnet
mkdir -p $ARWEAVE_DIR/arweave-build/testnet
