#!/bin/bash
set -e

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"

# Prevent concurrent cron jobs
LOCKFILE="/tmp/run-all.lock"

exec 9>"$LOCKFILE"
if ! flock -n 9; then
    echo "⛔ Another run-all instance is already running. Exiting."
    exit 0
fi


# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_ALL_LOG_DIR="$SCRIPT_DIR/../run-all-logs"

# -----------------------------
# Cleanup on ANY exit
# -----------------------------
cleanup() {
    echo
    echo "[!] Script exited — ensuring LXCs are cleaned up..."
    "$SCRIPT_DIR/destroy-lxcs.sh" || true
}
trap cleanup EXIT

# Make run all script's log directory
mkdir -p "$RUN_ALL_LOG_DIR"

# Timestamped log file (will be made for each execution)
LOG_FILE="$RUN_ALL_LOG_DIR/run-all_$(date +%F_%H-%M-%S).log"

# Redirect all stdout/stderr to log
exec > >(tee -a "$LOG_FILE") 2>&1

# Go to script dir
cd "$SCRIPT_DIR"

NUM_LXCS=${1:-3}
# PREFIX=${2:-ovpn-test-}

# Start timer
START_TIME=$(date +%s)

echo "➡️  Starting test run at: $(date)"

# PAUSED TEMPORARILY 

# Fetch fresh ovpn config files
#"$SCRIPT_DIR/fetch-ovpn-files.sh" || echo "⚠️ Warning: Fetch failed — old files will be used."

# Split .ovpn files based on remotes (OPTIONAL)
# If you want to enable remote-level cloning of ovpn files, then first do this:
# In file: start-tests.sh: Update variable named:"OVPN_DIR" from "ovpn-files" to "ovpn-files-split"
# Uncomment line below if you want remote-level ovpn file cloning
# "$SCRIPT_DIR/split-ovpn-remotes.sh" 

# Create LXCs
"$SCRIPT_DIR/launch-lxcs.sh" "$NUM_LXCS"

# Start tests
"$SCRIPT_DIR/start-tests.sh"

# Fetch logs
"$SCRIPT_DIR/fetch-logs.sh"

# Make results readable (OPTIONAL, must enable with "split-ovpn-remotes.sh", otherwise results will be messy)
# "$SCRIPT_DIR/make-logs-compact.sh"

# Destory LXCs at the end
"$SCRIPT_DIR/destroy-lxcs.sh"


# End timer
END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))

# Convert seconds → HH:MM:SS
printf -v RUNTIME '%02d:%02d:%02d' \
    $((ELAPSED/3600)) $(( (ELAPSED%3600)/60 )) $((ELAPSED%60))

echo "⏳ Total runtime: $RUNTIME"
echo "🏁 Completed at: $(date)"
