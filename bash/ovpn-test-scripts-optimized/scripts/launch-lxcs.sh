#!/bin/bash
set -e

N=${1:-3}
PREFIX=${2:-ovpn-test}
TEMPLATE="ovpn-template-alpine"

echo "➡️ Creating $N test LXCs using template '$TEMPLATE'"

# # -------------------------------------------------------------------
# # Create template if missing
# # -------------------------------------------------------------------

# if ! lxc list | awk '{print $2}' | grep -q "^$TEMPLATE$"; then
#     echo "📌 Template not found — creating it..."
#     lxc launch ubuntu:noble "$TEMPLATE"

#     echo "📦 Installing dependencies..."
#     lxc exec "$TEMPLATE" -- bash -c "
#         apt update &&
#         apt install -y openvpn curl jq
#     "

#     echo "⏹ Stopping template..."
#     lxc stop "$TEMPLATE"

#     echo "📸 Creating snapshot 'base'..."
#     lxc snapshot "$TEMPLATE" base
# else
#     echo "✔️ Template already exists. Using it."
# fi

# -------------------------------------------------------------------
# Create alpine template if missing
# -------------------------------------------------------------------

if ! lxc list | awk '{print $2}' | grep -q "^$TEMPLATE$"; then
    echo "📌 Template not found — creating it..."
    # Launch minimal Alpine container
    lxc launch images:alpine/3.22 "$TEMPLATE"

    echo "📦 Installing minimal dependencies..."
    lxc exec "$TEMPLATE" -- sh -c '
    MAX_RETRIES=5
    for i in $(seq 1 $MAX_RETRIES); do
        if apk update && apk add --no-cache openvpn curl bash jq iproute2 iputils coreutils sudo; then
            echo "✅ Dependencies installed successfully"
            break
        else
            echo "⚠️ apk failed, retrying ($i/$MAX_RETRIES)..."
            sleep 2
        fi
    done
    '

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
# Start timer for LXC cloning
START_TIME=$(date +%s)

# # Sequential LXC cloning
# for i in $(seq 1 $N); do
#     NAME="$PREFIX-$i"
#     echo "🚀 Creating clone: $NAME"

#     lxc copy "$TEMPLATE"/base "$NAME"
#     lxc start "$NAME"
# done

# Parallel LXC Cloning
for i in $(seq 1 $N); do
    NAME="$PREFIX-$i"
    echo "🚀 Creating clone: $NAME"

    # Clone and start in background
    (
        lxc copy "$TEMPLATE"/base "$NAME"
        lxc start "$NAME"
        echo "✅ $NAME ready"
    ) &
    PIDS+=($!)
done

# Wait for all background jobs to finish
for pid in "${PIDS[@]}"; do
    wait "$pid"
done

echo "✅ All $N LXCs created successfully!"

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
# Convert seconds → HH:MM:SS
printf -v RUNTIME '%02d:%02d:%02d' \
    $((ELAPSED/3600)) $(( (ELAPSED%3600)/60 )) $((ELAPSED%60))
echo "⏳ Total runtime for LXC cloning: $RUNTIME"