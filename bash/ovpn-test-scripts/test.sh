#!/bin/bash

# echo "=============== From LXC: $(basename "$LXC_NAME") Testing all .ovpn config files ==============="

LOG="master_log.txt"
: > "$LOG"   # clear master log file

echo -e "\n\n========================== LXC Name: $(basename "$LXC_NAME") ==========================\n" >> "$LOG"

#------------------------- RAGE-QUIT PROTECTION -------------------------------

VPN_PIDS=()
TMP_FILES=() # will delete all temp files created so far after ctrl+c

cleanup() {
    echo
    echo "[!] CTRL+C detected — cleaning up..."

    for pid in "${VPN_PIDS[@]}"; do
        sudo kill "$pid" 2>/dev/null
    done

    for f in "${TMP_FILES[@]}"; do
        rm -f "$f" 2>/dev/null
    done

    rm -f logs_temp_*.txt 2>/dev/null

    echo "[!] Cleanup done. Exiting safely."
    exit 1
}

trap cleanup INT

#------------------------------------------------------------------------------

# Find all ovpn files in current directory
mapfile -t OVPN_FILES < <(find "$(dirname "$0")" -maxdepth 1 -type f -name "*.ovpn")

if [[ ${#OVPN_FILES[@]} -eq 0 ]]; then
    echo "No ovpn files found."
    exit 0
fi

# -----------------------------
# Final summary storage
# -----------------------------
declare -A SUMMARY_PASSED  # key = config_name|IP, value = ports string
declare -A SUMMARY_FAILED  # key = config_name|IP, value = ports string
declare -A SUMMARY_NO_INTERNET

# ============================================================================

TOTAL_FILES=${#OVPN_FILES[@]}
INDEX=1

for CONFIG in "${OVPN_FILES[@]}"; do

    # echo
    # echo "=================================================================="
    # echo "📌 Starting tests for: $CONFIG"
    # echo "📄 File $INDEX of $TOTAL_FILES"
    # echo "=================================================================="

    FILE_LOG="log_$(basename "$CONFIG").txt"
    : > "$FILE_LOG"

    declare -A PASSED_MAP=()
    declare -A FAILED_MAP=()
    declare -A NO_INTERNET_MAP=()

    # Extract all remotes from the file
    readarray -t REMOTES < <(grep -E "^remote " "$CONFIG" | awk '{print $2" "$3}')

    if [[ ${#REMOTES[@]} -eq 0 ]]; then
        echo "⚠️  No 'remote' lines found in $CONFIG"
        continue
    fi

    # echo -e "\n\n================ CONFIG: $(basename "$CONFIG") ================\n" >> "$LOG"

    for remote in "${REMOTES[@]}"; do
        IP="${remote% *}"
        PORT="${remote#* }"

        TMP_CONFIG="$(mktemp)"
        TMP_FILES+=("$TMP_CONFIG")

        cp "$CONFIG" "$TMP_CONFIG"

        # Disable all other remotes
        sed -i 's/^remote /# remote /g' "$TMP_CONFIG"

	# Insert our target remote as primary
        sed -i "2i remote $IP $PORT" "$TMP_CONFIG"

        # echo
        # echo "[INFO] Testing $IP:$PORT in $(basename "$CONFIG")"
        echo "[INFO] $IP $PORT ################# " >> "$FILE_LOG"
	echo "[INFO] $IP $PORT ################# " >> "$LOG"

        IP_PORT_LOG="logs_temp_${IP}_${PORT}.txt"

	MAX_WAIT=10

	# Ping vars
	PING_TARGET="8.8.8.8"
	PING_COUNT=4
	PING_TIMEOUT=2

	# Starting VPN ############
	timeout $MAX_WAIT sudo openvpn --config "$TMP_CONFIG" >> "$IP_PORT_LOG" 2>&1 &
        VPN_PID=$!
        VPN_PIDS+=("$VPN_PID")

        SUCCESS_KEYWORD="Initialization Sequence Completed"
	IP_CONNECTION_KEYWORD="[server] Peer Connection Initiated with [AF_INET]$IP:$PORT"

	SECONDS_WAITED=0
        CONNECTED=0

        # echo -n "  → Waiting for connection"

        while [ $SECONDS_WAITED -lt $MAX_WAIT ]; do
            # echo -n "."

	    # --- Test Layer 1: Check if Success keyword has appeared in log ---
            if [ -f "$IP_PORT_LOG" ] && \
               tail -n 20 "$IP_PORT_LOG" | grep -Fq "$SUCCESS_KEYWORD"; then

		# CURRENT_IP=$(curl -m 5 -s -4 ifconfig.co)

                # --- Test Layer 2: Check if OpenVPN actually connected to the target remote ---
		if tail -n 60 "$IP_PORT_LOG" | grep -Fq "$IP_CONNECTION_KEYWORD"; then

		    # --- Test Layer 3: Connectivity check (ping to address set in PING_TARGET variable) ---
		    sleep 1

#    		    if ping -c "$PING_COUNT" -W "$PING_TIMEOUT" "$PING_TARGET" >/dev/null 2>&1; then
#        	        PASSED_MAP["$IP"]+="$PORT "
#        		CONNECTED=1
#        		break
#    		    else
#        	        echo "[FAIL] Ping check failed after VPN connection ($IP:$PORT)" >> "$FILE_LOG"
#        	        echo "[FAIL] Ping check failed after VPN connection ($IP:$PORT)" >> "$LOG"
#			break
#    		    fi

		    if ping -c "$PING_COUNT" -W "$PING_TIMEOUT" "$PING_TARGET" >/dev/null 2>&1; then
    			PASSED_MAP["$IP"]+="$PORT "
    			CONNECTED=1
    			break
		    else
    			echo "[WARN] VPN connected but no internet access ($IP:$PORT)" >> "$FILE_LOG"
    			echo "[WARN] VPN connected but no internet access ($IP:$PORT)" >> "$LOG"
    			NO_INTERNET_MAP["$IP"]+="$PORT "
    			CONNECTED=2
    			break
		    fi
		fi

            fi

            sleep 1
            ((SECONDS_WAITED++))
        done

	# If never connected then CONNECTED will be 0
        if [[ $CONNECTED -eq 0 ]]; then
            # CURIP=$(curl -m 5 -s -4 ifconfig.co)
            # echo
            # echo "  ❌ FAILURE: $IP:$PORT – Current IP: $CURIP - $SECONDS_WAITED seconds"
            FAILED_MAP["$IP"]+="$PORT "
	    for pid in "${VPN_PIDS[@]}"; do sudo kill "$pid" 2>/dev/null; done
	    VPN_PIDS=()
        fi

        # Append test log to file log & master log
        cat "$IP_PORT_LOG" >> "$FILE_LOG"
        cat "$IP_PORT_LOG" >> "$LOG"
        rm -f "$IP_PORT_LOG"

        # sudo kill "$VPN_PID" 2>/dev/null
	for pid in "${VPN_PIDS[@]}"; do
	    sudo kill "$pid" 2>/dev/null
        done
	VPN_PIDS=()
    done

    # echo
    # echo "--------------------------------------------------------"
    # echo "📌 SUMMARY for $(basename "$CONFIG")"
    # echo "--------------------------------------------------------"

    # echo "  ✅ Successful remotes:"
    # for ip in "${!PASSED_MAP[@]}"; do
    #    PORTS="${PASSED_MAP[$ip]}"
    #    echo "    IP: $ip"
    #    echo "    Ports: ${PORTS// /, }"
    # done

    # echo "  ❌ Failed remotes:"
    # for ip in "${!FAILED_MAP[@]}"; do
    #    PORTS="${FAILED_MAP[$ip]}"
    #    echo "    IP: $ip"
    #    echo "    Ports: ${PORTS// /, }"
    # done

    # echo

    # -----------------------------
    # Save per-file results in summary arrays
    # -----------------------------
    for ip in "${!PASSED_MAP[@]}"; do
        SUMMARY_PASSED["$(basename "$CONFIG")|$ip"]="${PASSED_MAP[$ip]}"
    done
    for ip in "${!FAILED_MAP[@]}"; do
	SUMMARY_FAILED["$(basename "$CONFIG")|$ip"]="${FAILED_MAP[$ip]}"
    done
    for ip in "${!NO_INTERNET_MAP[@]}"; do
    	SUMMARY_NO_INTERNET["$(basename "$CONFIG")|$ip"]="${NO_INTERNET_MAP[$ip]}"
    done

    ((INDEX++))
done

# ============================================================================

# echo
# echo "###########################################################################"
# echo "##################### GLOBAL SUMMARY FROM LXC: $(basename "$LXC_NAME") ################"
# echo "###########################################################################"

# echo

for CONFIG in *.ovpn; do
    HAS_OUTPUT=0

    # Check if this config has failures or no-internet entries
    for key in "${!SUMMARY_FAILED[@]}" "${!SUMMARY_NO_INTERNET[@]}"; do
        if [[ $key == "$CONFIG|"* ]]; then
            HAS_OUTPUT=1
            break
        fi
    done

    # Skip clean configs entirely
    [[ $HAS_OUTPUT -eq 0 ]] && continue

    echo
    echo "========================================================"
    echo "CONFIG FILE: $CONFIG"
    echo "========================================================"

    # -----------------------------
    # ⚠️ NO INTERNET
    # -----------------------------
    SECTION_PRINTED=0
    for key in "${!SUMMARY_NO_INTERNET[@]}"; do
        [[ $key == "$CONFIG|"* ]] || continue

        [[ $SECTION_PRINTED -eq 0 ]] && {
            echo
            echo "  ⚠️ Connected but NO internet:"
            SECTION_PRINTED=1
        }

        IP="${key#*|}"
        PORTS="${SUMMARY_NO_INTERNET[$key]}"
        echo "    - $IP  → Ports: ${PORTS// /, }"
    done

    # -----------------------------
    # ❌ FAILED
    # -----------------------------
    SECTION_PRINTED=0
    for key in "${!SUMMARY_FAILED[@]}"; do
        [[ $key == "$CONFIG|"* ]] || continue

        [[ $SECTION_PRINTED -eq 0 ]] && {
            echo
            echo "  ❌ Failed remotes:"
            SECTION_PRINTED=1
        }

        IP="${key#*|}"
        PORTS="${SUMMARY_FAILED[$key]}"
        echo "    - $IP  → Ports: ${PORTS// /, }"
    done

    echo
done


# --------------------------------------------- OLD SUMMARY CODE ---------------------------------------------
# for CONFIG in *.ovpn; do
#     echo "--------------------------------------------------------"
#     echo "CONFIG FILE: $CONFIG"

#     echo "  ✅ Successful remotes:"
#     for key in "${!SUMMARY_PASSED[@]}"; do
#         [[ $key == "$CONFIG|"* ]] || continue
#         IP="${key#*|}"
#         PORTS="${SUMMARY_PASSED[$key]}"
#         echo "    IP: $IP"
#         echo "    Ports: ${PORTS// /, }"
#     done

#     echo "  ⚠️ Connected but NO internet:"
#     for key in "${!SUMMARY_NO_INTERNET[@]}"; do
#         [[ $key == "$CONFIG|"* ]] || continue
#         IP="${key#*|}"
#         PORTS="${SUMMARY_NO_INTERNET[$key]}"
#         echo "    IP: $IP"
#         echo "    Ports: ${PORTS// /, }"
#     done

#     echo "  ❌ Failed remotes:"
#     for key in "${!SUMMARY_FAILED[@]}"; do
#         [[ $key == "$CONFIG|"* ]] || continue
#         IP="${key#*|}"
#         PORTS="${SUMMARY_FAILED[$key]}"
#         echo "    IP: $IP"
#         echo "    Ports: ${PORTS// /, }"
#     done

#     echo
# done
# --------------------------------------------- OLD SUMMARY CODE END ---------------------------------------------

# -----------------------------
# Final cleanup of temp files
# -----------------------------
for f in "${TMP_FILES[@]}"; do
    rm -f "$f" 2>/dev/null
done
TMP_FILES=()

# echo "=========================================================="

# echo
# echo "All logs saved to: $LOG"
# echo "==========================================================================="
