#!/bin/bash
set -e

PREFIX=${1:-ovpn-test-}
LXCS=( $(lxc list | awk "/$PREFIX/ {print \$2}") )

echo "🗑️ Deleting LXCs with prefix '$PREFIX'..."
for LXC in "${LXCS[@]}"; do
    lxc delete --force "$LXC"
    echo "   - Deleted $LXC"
done

echo "✅ All LXCs deleted."
