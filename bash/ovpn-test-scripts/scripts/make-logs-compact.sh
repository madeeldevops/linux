#!/bin/bash
set -e

DEST_DIR=${2:-$PWD/../logs}

awk '
/^CONFIG FILE:/ {
  file=$3
  sub(/\.ovpn$/, "", file)

  split(file, a, "__")
  base=a[1]

  split(a[2], b, "_")
  ip=b[1]
  port=b[2]

  key=base "|" ip
  ports[key]=ports[key] port ","
}
END {
  for (k in ports) {
    split(k, x, "|")
    printf "\n%s\n  %s → failed ports: %s\n", x[1], x[2], ports[k]
  }
}
' $DEST_DIR/results_merged.log > $DEST_DIR/results_compact.log

echo "✅ Made compact logs in $DEST_DIR"
