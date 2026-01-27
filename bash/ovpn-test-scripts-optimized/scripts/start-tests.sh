#!/bin/bash
set -e

# Start timer for total time of files distribution.
START_TIME=$(date +%s)

# Temp directory to store tar file
TMP_DIR=$(mktemp -d)

PREFIX=${1:-ovpn-test-}
OVPN_DIR=${2:-$PWD/../ovpn-files-split}
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

# # Push files to relevant lxcs (sequential)
# for i in $(seq 0 $((N-1))); do

#     # Loop through each LXC. Get the list of files assigned to this LXC. Count them for reporting.
#     LXC_NAME="${LXCS[$i]}"
#     FILE_LIST=${ASSIGN[$i]}

#     FILES_FOR_LXC=( $FILE_LIST )

#     COUNT=${#FILES_FOR_LXC[@]}
#     echo "   - $LXC_NAME gets $COUNT files"

#     # Create tar file which will contail all ovpn files assigned to this LXC
#     TAR_FILE="$TMP_DIR/${LXC_NAME}.tar"
#     tar -cf "$TAR_FILE" -C "$OVPN_DIR" \
#         $(printf '%s\n' "${FILES_FOR_LXC[@]}" | xargs -n1 basename)

#     # push tar file in lxc root
#     lxc file push "$TAR_FILE" "$LXC_NAME"/root/ovpns.tar
#     # extract everything in ovpns.tar in /root
#     lxc exec "$LXC_NAME" -- tar -xf /root/ovpns.tar -C /root

#     # Copy the test script into the LXC as well.
#     lxc file push "$TEST_SCRIPT" "$LXC_NAME"/root/
# done
# echo "✅ File distribution completed"

# Push files to relevant lxcs (parallel)
echo "📂 Distributing files to LXCs in parallel..."
for i in $(seq 0 $((N-1))); do
(
    # Loop through each LXC. Get the list of files assigned to this LXC. Count them for reporting.
    LXC_NAME="${LXCS[$i]}"
    FILE_LIST=${ASSIGN[$i]}
    FILES_FOR_LXC=( $FILE_LIST )

    COUNT=${#FILES_FOR_LXC[@]}
    echo "   - $LXC_NAME gets $COUNT files"

    # Create tar file which will contail all ovpn files assigned to this LXC
    TAR_FILE="$TMP_DIR/${LXC_NAME}.tar"
    tar -cf "$TAR_FILE" -C "$OVPN_DIR" \
        $(printf '%s\n' "${FILES_FOR_LXC[@]}" | xargs -n1 basename)

    # Push tar file in lxc root
    lxc file push "$TAR_FILE" "$LXC_NAME"/root/ovpns.tar
    # extract everything in ovpns.tar in /root
    lxc exec "$LXC_NAME" -- tar -xf /root/ovpns.tar -C /root

    # Copy the test script into the LXC as well.
    lxc file push "$TEST_SCRIPT" "$LXC_NAME"/root/

)&
done

# Wait for *all* LXCs to finish receiving files
wait

echo "✅ File distribution completed"

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
# Convert seconds → HH:MM:SS
printf -v RUNTIME '%02d:%02d:%02d' \
    $((ELAPSED/3600)) $(( (ELAPSED%3600)/60 )) $((ELAPSED%60))
echo "⏳ Total runtime for files distribution: $RUNTIME"

# Start timer which will capture time required to START tests in all LXCs
START_TIME=$(date +%s)
echo "🚀 Starting tests in all LXCs..."
for LXC_NAME in "${LXCS[@]}"; do
    lxc exec "$LXC_NAME" -- bash -c "
        LXC_NAME=$LXC_NAME nohup bash /root/test.sh \
        >> /root/results.log 2>&1;
        touch /root/.tests_done
    " &
done
echo "✅ Tests Started in All LXCs"

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
# Convert seconds → HH:MM:SS
printf -v RUNTIME '%02d:%02d:%02d' \
    $((ELAPSED/3600)) $(( (ELAPSED%3600)/60 )) $((ELAPSED%60))
echo "⏳ Total runtime for for starting tests in all LXCs: $RUNTIME"
