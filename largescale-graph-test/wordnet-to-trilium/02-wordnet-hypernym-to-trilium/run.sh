#!/usr/bin/env bash
# run-import.sh
# Run add-to-trilium-bulk.py with auto-restart, exponential backoff, infinite retries.
# Activates the venv and prints logs directly to the terminal.

set -euo pipefail

INPUT_FILE="syn-entries.csv"
SCRIPT="./add-to-trilium-bulk-synsets.py"

BASE_DELAY=5          # start with 5 seconds
MAX_DELAY=600         # cap at 10 minutes

retry=0
delay=$BASE_DELAY

echo "[$(date)] Starting bulk import with infinite retries..."

# activate virtual environment
if [ -f "./.venv/bin/activate" ]; then
    # shellcheck disable=SC1091
    source "./.venv/bin/activate"
    echo "[$(date)] ✅ Virtual environment activated."
else
    echo "[$(date)] ❌ Virtual environment not found at ./.venv/bin/activate"
    exit 1
fi

while true; do
    if python "$SCRIPT" --input "$INPUT_FILE"; then
        echo "[$(date)] ✅ Import finished successfully."
        break
    else
        retry=$((retry + 1))
        echo "[$(date)] ⚠️ Import failed (attempt $retry). Retrying in $delay seconds..."
        sleep "$delay"
        # exponential backoff
        delay=$((delay * 2))
        if [ "$delay" -gt "$MAX_DELAY" ]; then
            delay=$MAX_DELAY
        fi
    fi
done

