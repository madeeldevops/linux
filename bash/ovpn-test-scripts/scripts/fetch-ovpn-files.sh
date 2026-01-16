#!/bin/bash
set -e

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVPN_DIR="$SCRIPT_DIR/../ovpn-files"


REMOTE_IP="<ip>"
REMOTE_USER="<user>"
REMOTE_PATH="<vpn_files_path>"

MAX_RETRIES=5
RETRY_DELAY=10   # seconds

TMP_DIR=$(mktemp -d)

echo "📥 Fetching new .ovpn files to temporary directory $TMP_DIR ..."

RETRY_COUNT=0
while true; do
    if scp -P 54003 "$REMOTE_USER@$REMOTE_IP:$REMOTE_PATH"/nak-*.ovpn "$TMP_DIR/" ; then
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
