#!/usr/bin/env bash
set -euo pipefail

ASSETS_DIR="assets/openimages"
TSV_FILE="$ASSETS_DIR/open-images-dataset-train0.tsv"
mkdir -p "$ASSETS_DIR"

# Download TSV if not already present
if [[ ! -f "$TSV_FILE" ]]; then
  echo "📂 Downloading Open Images train0.tsv..."
  wget -c -O "$TSV_FILE" "https://storage.googleapis.com/cvdf-datasets/oid/open-images-dataset-train0.tsv"
fi

LIMIT=10000   # total images to fetch
PER_FOLDER=1000

echo "⚙️ Downloading $LIMIT images into folders of $PER_FOLDER..."

tail -n +2 "$TSV_FILE" | head -n "$LIMIT" | cut -d'>' -f1 | \
  nl -w1 -s$'\t' | while IFS=$'\t' read -r lineno url; do
    folder=$(printf "%02d" $(((lineno-1)/PER_FOLDER)))
    mkdir -p "$ASSETS_DIR/$folder"
    outfile="$ASSETS_DIR/$folder/${lineno}.jpg"

    if [[ -f "$outfile" ]]; then
      echo "⏭️ [$lineno/$LIMIT] Skipping $outfile (already exists)"
      continue
    fi

    echo "📥 [$lineno/$LIMIT] → saving to $outfile"
    delay=2
    attempt=1
    while true; do
        if wget -c -O "$outfile" "$url"; then
            # success
            break
        fi

        status=$?

        if [ $status -eq 8 ]; then
            echo "⚠️ Attempt $attempt failed (HTTP error, maybe 429). Retrying in $delay seconds..."
            sleep $delay
            delay=$((delay * 2))
            if [ $delay -gt 60 ]; then
                delay=60
            fi
            attempt=$((attempt + 1))
        else
            echo "❌ Failed with non-retryable error (code $status)."
            break
        fi
    done
  done

echo "✅ Done. Images saved in $ASSETS_DIR/00, $ASSETS_DIR/01, …"

