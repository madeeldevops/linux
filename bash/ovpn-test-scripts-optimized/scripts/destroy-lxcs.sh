#!/bin/bash
set -e

# Start timer for destroying LXCs
START_TIME=$(date +%s)

PREFIX=${1:-ovpn-test-}
LXCS=( $(lxc list | awk "/$PREFIX/ {print \$2}") )

echo "🗑️ Deleting LXCs with prefix '$PREFIX'..."
# for LXC in "${LXCS[@]}"; do
#     lxc delete --force "$LXC"
#     echo "   - Deleted $LXC"
# done

# Parallel Deletion
# for LXC in "${LXCS[@]}"; do
#     lxc delete --force "$LXC"
#     echo "   - Deleted $LXC"
# done

# Controlled Parallel Deletion
# lxc list | awk "/$PREFIX/ {print \$2}" | \
# xargs -n 1 -P 8 -I {} bash -c '
#     lxc delete --force "{}"
#     echo "   - Deleted {}"
# '

# Controlled Parallel Deletion 2
lxc list | awk "/$PREFIX/ {print \$2}" | \
xargs -P 8 -I {} bash -c '
    lxc delete --force "{}"
    echo "   - Deleted {}"
'

echo "✅ All LXCs deleted."

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
# Convert seconds → HH:MM:SS
printf -v RUNTIME '%02d:%02d:%02d' \
    $((ELAPSED/3600)) $(( (ELAPSED%3600)/60 )) $((ELAPSED%60))
echo "⏳ Total runtime for destroying all LXCs: $RUNTIME"
