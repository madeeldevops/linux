#!/bin/bash
set -e

PREFIX=${1:-ovpn-test-}
# DEST_DIR=${2:-$PWD/../logs}
DEST_DIR=${2:-$(realpath "$(dirname "$0")/../logs")}

# Remove old logs directory
echo "🧹 Cleaning previous logs in $DEST_DIR..."
# Protect against empty values and root value
if [[ -n "$DEST_DIR" && "$DEST_DIR" != "/" ]]; then
    rm -rf "$DEST_DIR"
fi

LXCS=( $(lxc list | awk "/$PREFIX/ {print \$2}") )

# Wait for all LXCs to finish
echo "⏳ Waiting for all LXCs to finish tests..."
for LXC in "${LXCS[@]}"; do
    while ! lxc exec "$LXC" -- test -f /root/.tests_done; do
        sleep 5
    done
    echo "✅ $LXC finished tests."
done

# make logs directory after lxc finished tests
mkdir -p "$DEST_DIR"

# Pull logs from each LXC
for LXC in "${LXCS[@]}"; do
    mkdir -p "$DEST_DIR/$LXC"

    # pull results.log
    lxc file pull "$LXC"/root/results.log "$DEST_DIR/$LXC/" 2>/dev/null || true

    # pull master_log.txt 
    lxc file pull "$LXC"/root/master_log.txt "$DEST_DIR/$LXC/" 2>/dev/null || true
done

# Merge logs
cat "$DEST_DIR"/"$PREFIX"*/master_log.txt > "$DEST_DIR/master_log_merged.txt" 2>/dev/null || true
cat "$DEST_DIR"/"$PREFIX"*/results.log > "$DEST_DIR/results_merged.log" 2>/dev/null || true

echo "✅ Logs fetched and merged in $DEST_DIR"
