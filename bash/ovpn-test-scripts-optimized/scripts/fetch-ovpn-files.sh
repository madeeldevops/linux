#!/bin/bash
set -e

# start time for fetching ovpn files
START_TIME=$(date +%s)

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVPN_DIR="$SCRIPT_DIR/../ovpn-files"


REMOTE_IP="<IP>"
REMOTE_USER="<USER>"
REMOTE_PATH="<PATH>"

MAX_RETRIES=5
RETRY_DELAY=10   # seconds

TMP_DIR=$(mktemp -d)

echo "📥 Fetching new .ovpn files to temporary directory $TMP_DIR ..."

RETRY_COUNT=0
while true; do
    if scp -P <PORT> "$REMOTE_USER@$REMOTE_IP:$REMOTE_PATH"/nak-*.ovpn "$TMP_DIR/" ; then
        echo "✅ Fetch succeeded. Updating local $OVPN_DIR..."
        mkdir -p "$OVPN_DIR"
        rm -f "$OVPN_DIR"/nak-*.ovpn || true
        mv "$TMP_DIR"/* "$OVPN_DIR/"
        rm -rf "$TMP_DIR"
        echo "✅ All .ovpn files updated in $OVPN_DIR"
        break
    else
        ((RETRY_COUNT++))
        if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
            echo "❌ Failed to fetch .ovpn files after $MAX_RETRIES attempts."
            echo "⚠️ Keeping old .ovpn files in $OVPN_DIR intact."
            rm -rf "$TMP_DIR"
            exit 1
        fi
        echo "⚠️ SCP failed, retrying in $RETRY_DELAY seconds... (Attempt $RETRY_COUNT/$MAX_RETRIES)"
        sleep $RETRY_DELAY
    fi
done

END_TIME=$(date +%s)
# Convert seconds → HH:MM:SS
printf -v RUNTIME '%02d:%02d:%02d' \
    $((ELAPSED/3600)) $(( (ELAPSED%3600)/60 )) $((ELAPSED%60))
echo "⏳ Total runtime for fetching ovpn files: $RUNTIME"
