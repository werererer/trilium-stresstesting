#!/usr/bin/env bash
# make-big-lorem.sh
# Create a giant Lorem Ipsum text file for stress testing.

set -euo pipefail

# ----------------------------------------
# Config
# ----------------------------------------
SIZE="1G"                # <-- change this to your desired size (e.g. 500M, 2G, 50M)
OUTFILE="big-lorem.txt"  # output filename

# Standard Lorem Ipsum paragraph
LOREM="Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

# ----------------------------------------
# Main
# ----------------------------------------
echo "📦 Creating '$OUTFILE' with endless Lorem Ipsum (size $SIZE)..."

# Repeat Lorem Ipsum until target size is reached
yes "$LOREM" | head -c "$SIZE" > "$OUTFILE"

echo "✅ Done: $(ls -lh "$OUTFILE")"

