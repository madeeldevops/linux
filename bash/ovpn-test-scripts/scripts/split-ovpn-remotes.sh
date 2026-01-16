#!/bin/bash
set -euo pipefail

SRC_DIR="../ovpn-files"
DST_DIR="../ovpn-files-split"

mkdir -p "$DST_DIR"
rm -f "$DST_DIR"/*.ovpn

echo "🔄 Splitting ovpn configs from '$SRC_DIR' → '$DST_DIR'"

for f in "$SRC_DIR"/*.ovpn; do
    base=$(basename "$f" .ovpn)

    grep '^remote ' "$f" | while read -r _ ip port; do
        out="$DST_DIR/${base}__${ip}_${port}.ovpn"

        # Remove all remote lines
        sed '/^remote /d' "$f" > "$out"

        # Insert exactly one remote near top (after header)
        sed -i "5i remote $ip $port" "$out"
    done
done

count=$(ls -1 "$DST_DIR"/*.ovpn 2>/dev/null | wc -l)
echo "✅ Generated $count single-remote ovpn files"
