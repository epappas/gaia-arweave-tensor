#!/bin/bash

ARWEAVE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if ! $ARWEAVE_DIR/testnet/assert_testnet.sh; then
	echo "Error: This script must be run on a testnet server."
	exit 1
fi

mkdir -p $ARWEAVE_DIR/arweave-build/mainnet
rm -rf $ARWEAVE_DIR/arweave-build/mainnet/*

echo "$0 $@" > $ARWEAVE_DIR/arweave-build/mainnet/build.command

cd $ARWEAVE_DIR
rm $ARWEAVE_DIR/_build/prod/rel/arweave/*.tar.gz
$ARWEAVE_DIR/rebar3 as prod tar
tar xf $ARWEAVE_DIR/_build/prod/rel/arweave/arweave-*.tar.gz -C $ARWEAVE_DIR/arweave-build/mainnet

