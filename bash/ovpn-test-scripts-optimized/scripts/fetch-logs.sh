#!/bin/bash
set -e

PREFIX=${1:-ovpn-test-}

DEST_DIR=${2:-$(realpath "$(dirname "$0")/../logs")}
RAW_RESULTS_DIR="$(dirname "$DEST_DIR")/raw-results"

LXCS=( $(lxc list | awk "/$PREFIX/ {print \$2}") )

# Wait for all LXCs to finish
START_TIME=$(date +%s)

echo "⏳ Waiting for all LXCs to finish tests..."
for LXC in "${LXCS[@]}"; do
    while ! lxc exec "$LXC" -- test -f /root/.tests_done; do
        sleep 2
    done
    echo "✅ $LXC finished tests."
done

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
# Convert seconds → HH:MM:SS
printf -v RUNTIME '%02d:%02d:%02d' \
    $((ELAPSED/3600)) $(( (ELAPSED%3600)/60 )) $((ELAPSED%60))
echo "⏳ Total runtime for all tests in all LXCs to complete: $RUNTIME"

# Start timer for fetching master_logs, result_logs, new_result_logs and merging them into master_log_merged, results_merged, and new_results_merged.
START_TIME=$(date +%s)

# Remove old logs directory
echo "🧹 Cleaning previous logs in $DEST_DIR..."
# Protect against empty values and root value
if [[ -n "$DEST_DIR" && "$DEST_DIR" != "/" ]]; then
    rm -rf "$DEST_DIR"
fi

# make new logs directory
mkdir -p "$DEST_DIR"

# Pull logs from each LXC (parallel)
echo "📥 Fetching logs from all LXCs in parallel..."

for LXC in "${LXCS[@]}"; do
(
    echo "Fetching logs from $LXC"
    mkdir -p "$DEST_DIR/$LXC"

    lxc file pull "$LXC"/root/test_sh_output.log \
        "$DEST_DIR/$LXC/" 2>/dev/null || true

    lxc file pull "$LXC"/root/raw_results.log \
        "$DEST_DIR/$LXC/" 2>/dev/null || true

    lxc file pull "$LXC"/root/master_log.txt \
        "$DEST_DIR/$LXC/" 2>/dev/null || true
)&
done
# Wait for all pulls to complete
wait
echo "✅ Log fetching completed"

# Merge logs
echo "Merging logs from LXCs"
cat "$DEST_DIR"/"$PREFIX"*/master_log.txt > "$DEST_DIR/master_log_merged.txt" 2>/dev/null || true
cat "$DEST_DIR"/"$PREFIX"*/test_sh_output.log > "$DEST_DIR/test_sh_outputs_merged.log" 2>/dev/null || true

# Merge all RAW results from all LXCs.
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
mkdir -p "$RAW_RESULTS_DIR"
cat "$DEST_DIR"/"$PREFIX"*/raw_results.log > \
    "$RAW_RESULTS_DIR/raw_results_merged_${TIMESTAMP}.log" 2>/dev/null || true

echo "✅ Logs fetched and merged in $DEST_DIR"

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
# Convert seconds → HH:MM:SS
printf -v RUNTIME '%02d:%02d:%02d' \
    $((ELAPSED/3600)) $(( (ELAPSED%3600)/60 )) $((ELAPSED%60))
echo "⏳ Total runtime for fetching and merging all logs: $RUNTIME"
