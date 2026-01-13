#!/bin/bash
set -e

PREFIX=${1:-ovpn-test-}
OVPN_DIR=${2:-$PWD/../ovpn-files}
TEST_SCRIPT=${3:-$PWD/test.sh}

# Find all .ovpn files in specified ovpn directory
FILES=( "$OVPN_DIR"/*.ovpn )
TOTAL_FILES=${#FILES[@]}

if [ $TOTAL_FILES -eq 0 ]; then
    echo "❌ No .ovpn files found in $OVPN_DIR"
    exit 1
fi

# Get all LXCs with matching prefix
LXCS=( $(lxc list | awk "/$PREFIX/ {print \$2}") )
N=${#LXCS[@]}

if [ $N -eq 0 ]; then
    echo "❌ No LXCs found with prefix $PREFIX"
    exit 1
fi

# --------------------------------------------------------------
# ROUND ROBIN ASSIGNMENT EXPLANATION

# This is round-robin assignment, meaning:
# File 0 → LXC 0
# File 1 → LXC 1
# …
# File N → LXC 0 again

# Round robin ensures an even-ish distribution of .ovpn files.
# No LXC gets zero unless total files < number of LXCs.
# --------------------------------------------------------------

# Round-robin assignment

echo "📂 Distributing $TOTAL_FILES files across $N LXCs (round-robin)..."

# ASSIGN is an associative array that holds which files go to which LXC.
declare -A ASSIGN

for idx in "${!FILES[@]}"; do
    lxc_index=$(( idx % N ))
    ASSIGN[$lxc_index]="${ASSIGN[$lxc_index]} ${FILES[$idx]}"
done

# Push files to relevant lxcs and start tests
for i in $(seq 0 $((N-1))); do

    # Loop through each LXC. Get the list of files assigned to this LXC. Count them for reporting.
    LXC_NAME="${LXCS[$i]}"
    FILE_LIST=${ASSIGN[$i]}

    FILES_FOR_LXC=( $FILE_LIST )
    COUNT=${#FILES_FOR_LXC[@]}

    echo "   - $LXC_NAME gets $COUNT files"

    # Push the .ovpn files into /root/ of the current LXC in loop	.
    for f in "${FILES_FOR_LXC[@]}"; do
        lxc file push "$f" "$LXC_NAME"/root/
    done

    # Copy the test script into the LXC as well.
    lxc file push "$TEST_SCRIPT" "$LXC_NAME"/root/

    # Run the test script inside the LXC in the background. Output is redirected to results.log inside the LXC.
    # After the test finishes, it touches .tests_done as a flag file to let the host script know it finished.
    lxc exec "$LXC_NAME" -- bash -c "LXC_NAME=$LXC_NAME nohup bash /root/test.sh >> /root/results.log 2>&1; touch /root/.tests_done" &
done

echo "✅ Tests started in all LXCs."
