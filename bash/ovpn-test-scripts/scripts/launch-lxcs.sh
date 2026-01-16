#!/bin/bash
set -e

N=${1:-3}
PREFIX=${2:-ovpn-test}
TEMPLATE="ovpn-template"

echo "➡️ Creating $N test LXCs using template '$TEMPLATE'"

# -------------------------------------------------------------------
# Create template if missing
# -------------------------------------------------------------------

if ! lxc list | awk '{print $2}' | grep -q "^$TEMPLATE$"; then
    echo "📌 Template not found — creating it..."
    lxc launch ubuntu:noble "$TEMPLATE"

    echo "📦 Installing dependencies..."
    lxc exec "$TEMPLATE" -- bash -c "
        apt update &&
        apt install -y openvpn curl jq
    "

    echo "⏹ Stopping template..."
    lxc stop "$TEMPLATE"

    echo "📸 Creating snapshot 'base'..."
    lxc snapshot "$TEMPLATE" base
else
    echo "✔️ Template already exists. Using it."
fi

echo

# -------------------------------------------------------------------
# Destory Existing LXCs
# -------------------------------------------------------------------
./destroy-lxcs.sh

# -------------------------------------------------------------------
# Create N clones
# -------------------------------------------------------------------

for i in $(seq 1 $N); do
    NAME="$PREFIX-$i"
    echo "🚀 Creating clone: $NAME"

    lxc copy "$TEMPLATE"/base "$NAME"
    lxc start "$NAME"
done

echo "✅ All $N LXCs created successfully!"
