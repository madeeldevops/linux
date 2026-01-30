#!/usr/bin/env bash

# Start timer for turning data from results_merged.log into a prettier format
START_TIME=$(date +%s)

# Make report directory if it does not exist
REPORT_DIR="../clean-results"
mkdir -p "$REPORT_DIR"

# Defining output address for prettified timestamped report
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT="$REPORT_DIR/clean_results_${TIMESTAMP}.txt"

# Get latest raw-results-merged log file (this merged file contains raw results from all LXCs and will be prettified)
RAW_RESULTS_DIR="../raw-results"
INPUT=$(ls -1t "$RAW_RESULTS_DIR"/raw_results_merged_*.log 2>/dev/null | head -n 1)

# error out if no file present 
if [[ -z "$INPUT" ]]; then
    echo "❌ No raw_results_merged logs found in $RAW_RESULTS_DIR"
    exit 1
fi

> "$OUTPUT"

echo "Making Logs Readable"

awk '
{
    # Extract filename only
    split($1, p, "/")
    file = p[length(p)]

    # Split filename into parts
    split(file, a, "__")
    config = a[1] ".ovpn"

    ip = $2
    port = $3
    status = $4

    key = config "|" ip "|" status
    ports[key] = ports[key] port ", "

    configs[config] = 1
    ips[config, ip] = 1
    statuses[config, status] = 1
}

END {
    for (config in configs) {
        print "========================================================" >> "'"$OUTPUT"'"
        print "CONFIG FILE: " config >> "'"$OUTPUT"'"
        print "========================================================\n" >> "'"$OUTPUT"'"

        # SUCCESS
        if ((config, "SUCCESS") in statuses) {
            print "  ✅ Successful remotes:" >> "'"$OUTPUT"'"
            for (k in ports) {
                split(k, x, "|")
                if (x[1] == config && x[3] == "SUCCESS") {
                    printf "    - %s  → Ports: %s\n", x[2], ports[k] >> "'"$OUTPUT"'"
                }
            }
            print "" >> "'"$OUTPUT"'"
        }

        # FAILED
        if ((config, "FAILED") in statuses) {
            print "  ❌ Failed remotes:" >> "'"$OUTPUT"'"
            for (k in ports) {
                split(k, x, "|")
                if (x[1] == config && x[3] == "FAILED") {
                    printf "    - %s  → Ports: %s\n", x[2], ports[k] >> "'"$OUTPUT"'"
                }
            }
            print "" >> "'"$OUTPUT"'"
        }

        # NO_INTERNET (optional)
        if ((config, "NO_INTERNET") in statuses) {
            print "  ⚠️ No Internet remotes:" >> "'"$OUTPUT"'"
            for (k in ports) {
                split(k, x, "|")
                if (x[1] == config && x[3] == "NO_INTERNET") {
                    printf "    - %s  → Ports: %s\n", x[2], ports[k] >> "'"$OUTPUT"'"
                }
            }
            print "" >> "'"$OUTPUT"'"
        }
    }
}
' "$INPUT"

echo "Made Logs Readable"

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
# Convert seconds → HH:MM:SS
printf -v RUNTIME '%02d:%02d:%02d' \
    $((ELAPSED/3600)) $(( (ELAPSED%3600)/60 )) $((ELAPSED%60))
echo "⏳ Total runtime for making logs pretty: $RUNTIME"

