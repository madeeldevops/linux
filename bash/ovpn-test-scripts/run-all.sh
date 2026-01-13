#!/bin/bash
set -e

NUM_LXCS=${1:-3}
# PREFIX=${2:-ovpn-test-}

# Start timer
START_TIME=$(date +%s)

echo "➡️  Starting test run at: $(date)"

# Create LXCs
./launch-lxcs.sh "$NUM_LXCS"

# Start tests
./start-tests.sh

# Fetch logs
./fetch-logs.sh


# End timer
END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))

# Convert seconds → HH:MM:SS
printf -v RUNTIME '%02d:%02d:%02d' \
    $((ELAPSED/3600)) $(( (ELAPSED%3600)/60 )) $((ELAPSED%60))

echo "⏳ Total runtime: $RUNTIME"
echo "🏁 Completed at: $(date)"

# Ask if user wants to destroy LXCs
read -p "Do you want to destroy all LXCs? (y/n) " yn
case $yn in
    [Yy]* ) ./destroy-lxcs.sh;;
    * ) echo "LXCs left intact.";;
esac
