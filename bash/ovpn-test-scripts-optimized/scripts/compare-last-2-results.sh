#!/usr/bin/env bash
set -euo pipefail

# ================== PATHS ==================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RAW_RESULTS_DIR="$BASE_DIR/raw-results"
REPORT_DIR="$BASE_DIR/last-two-tests-comparison-reports"

#RAW_RESULTS_DIR="../raw-results"
#REPORT_DIR="../last-two-tests-comparison-reports"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_FILE="$REPORT_DIR/comparison_report_${TIMESTAMP}.txt"
# ============================================

mkdir -p "$REPORT_DIR"

mapfile -t LAST_TWO < <(
    ls -1t "$RAW_RESULTS_DIR"/raw_results_merged_*.log 2>/dev/null | head -n 2
)

if (( ${#LAST_TWO[@]} < 2 )); then
    echo "❌ Need at least two raw_results_merged logs to compare"
    exit 1
fi

# Older → Test1, Newer → Test2
TEST1_LOG="${LAST_TWO[1]}"
TEST2_LOG="${LAST_TWO[0]}"

echo "Old file: $TEST1_LOG"
echo "New file: $TEST2_LOG"

awk '
BEGIN { FS=" " }

# ---------- FIRST TEST ----------
FNR == NR {
    key = $1 "|" $2 "|" $3
    res1[key] = $4
    path[key] = $1
    ip[key]   = $2
    port[key] = $3
    next
}

# ---------- SECOND TEST ----------
{
    key = $1 "|" $2 "|" $3
    res2[key] = $4
}

# ---------- HELPERS ----------
function cfg_name(p, a) {
    sub(/^.*\//, "", p)
    split(p, a, "__")
    return a[1] ".ovpn"
}

function add(bucket, cfg, ipaddr, prt, k) {
    k = bucket "|" cfg "|" ipaddr
    ports[k] = ports[k] prt ", "
}

# ---------- COMPARE ----------
END {
    for (k in res1) {
        if (!(k in res2)) continue

        cfg = cfg_name(path[k])

        if (res1[k] == "FAILED" && res2[k] == "FAILED")
            add("FF", cfg, ip[k], port[k])
        else if (res1[k] == "SUCCESS" && res2[k] == "FAILED")
            add("SF", cfg, ip[k], port[k])
        else if (res1[k] == "FAILED" && res2[k] == "SUCCESS")
            add("FS", cfg, ip[k], port[k])
    }

    print_section("=========== ❌ ❌ FAILED in BOTH Test1 and Test 2 ===========", "FF")
    print_section("=========  ✅ ❌ PASSED in Test 1, FAILED in Test 2 =========", "SF")
    print_section("========== ❌ ✅ FAILED in Test 1, PASSED in Test 2 =========", "FS")
}

# ---------- OUTPUT ----------
function print_section(title, bucket, k, parts) {
    print "#############################################################"
    print title
    print "#############################################################"

    for (k in ports) {
        split(k, parts, "|")
        if (parts[1] != bucket) continue

        if (last_cfg != parts[2]) {
            print "\n========================================================"
            print "CONFIG FILE:", parts[2]
            # print "========================================================"
            last_cfg = parts[2]
        }

        print "  - " parts[3] "  → Ports: " ports[k]
    }

    last_cfg = ""
    print ""
}
' "$TEST1_LOG" "$TEST2_LOG" > "$OUTPUT_FILE"

echo "✅ Comparison report written to: $OUTPUT_FILE"
