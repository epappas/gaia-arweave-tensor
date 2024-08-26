#!/bin/bash

ARWEAVE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if ! $ARWEAVE_DIR/testnet/assert_testnet.sh; then
	echo "Error: This script must be run on a testnet server."
	exit 1
fi

if [[ ! -f "$ARWEAVE_DIR/arweave-build/mainnet/bin/start" ]]; then
    echo "Arweave start script not found. Please run rebuild_mainnet.sh first."
	exit 1
fi

SCREEN_CMD="screen -dmsL arweave $ARWEAVE_DIR/arweave-build/mainnet/bin/start"
address=""

# look in $ARWEAVE_DIR/arweave-data to determine this node's mining address and storage modules
for dir in $ARWEAVE_DIR/arweave-data/storage_modules/storage_module_*; do
	# get the storage_module directory names
	filename=$(basename $dir)

	# remove the leading storage_module_
	prefix="storage_module_"
	str="${filename#$prefix}"

    # Extract size, index, and address
    size=$(awk -F'_' '{print $1}' <<< "$str")
	index=$(awk -F'_' '{print $2}' <<< "$str")
	prefix="${size}_${index}_"
	address="${str#$prefix}"
    
    # Append to the screen command
    SCREEN_CMD="$SCREEN_CMD storage_module $index,$size,$address"
done

SCREEN_CMD="$SCREEN_CMD mining_addr $address \
debug \
data_dir $ARWEAVE_DIR/arweave-data \
peer ams-1.eu-central-1.arweave.net \
peer fra-1.eu-central-2.arweave.net \
header_sync_jobs 1"

echo "$SCREEN_CMD"
echo "$SCREEN_CMD" > $ARWEAVE_DIR/arweave-build/mainnet/run.command

cd $ARWEAVE_DIR/arweave-build/mainnet

eval "$SCREEN_CMD"