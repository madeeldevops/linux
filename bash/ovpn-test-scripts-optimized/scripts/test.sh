#!/bin/bash

LOG="master_log.txt"
: > "$LOG"   # clear master log file

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
declare -A SUMMARY_FAILED
declare -A SUMMARY_NO_INTERNET

# ============================================================================

TOTAL_FILES=${#OVPN_FILES[@]}
INDEX=1

for CONFIG in "${OVPN_FILES[@]}"; do

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

        # Success keywords
        SUCCESS_KEYWORD="Initialization Sequence Completed"
	    IP_CONNECTION_KEYWORD="[server] Peer Connection Initiated with [AF_INET]$IP:$PORT"

	    SECONDS_WAITED=0
        CONNECTED=0

        while [ $SECONDS_WAITED -lt $MAX_WAIT ]; do
	        
            # --- Test Layer 1: Check if Success keyword has appeared in log ---
            if [ -f "$IP_PORT_LOG" ] && \
               tail -n 20 "$IP_PORT_LOG" | grep -Fq "$SUCCESS_KEYWORD"; then
                
                # --- Test Layer 2: Check if OpenVPN actually connected to the target remote ---
		        if tail -n 60 "$IP_PORT_LOG" | grep -Fq "$IP_CONNECTION_KEYWORD"; then
  
                    # --- Test Layer 3: Connectivity check (ping to address set in PING_TARGET variable) ---
		            sleep 1
		            if ping -c "$PING_COUNT" -W "$PING_TIMEOUT" "$PING_TARGET" >/dev/null 2>&1; then
			            echo "$CONFIG $IP $PORT SUCCESS" >> raw_results.log
    			        CONNECTED=1
    			        break
		            else
    			        echo "[WARN] VPN connected but no internet access ($IP:$PORT)" >> "$FILE_LOG"
    			        echo "[WARN] VPN connected but no internet access ($IP:$PORT)" >> "$LOG"
			            echo "$CONFIG $IP $PORT NO_INTERNET" >> raw_results.log
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
	        echo "$CONFIG $IP $PORT FAILED" >> raw_results.log
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
done

# -----------------------------
# Final cleanup of temp files
# -----------------------------
for f in "${TMP_FILES[@]}"; do
    rm -f "$f" 2>/dev/null
done
TMP_FILES=()

