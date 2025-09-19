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
        if wget -c -O "$outfile" "$url" 2> >(tee err.log >&2); then
            # wget printed normally to terminal
            break
        fi

        status=$?

        if grep -q "429 Too Many Requests" err.log; then
            echo "⚠️ Attempt $attempt: got 429. Retrying in $delay seconds..."
            sleep $delay
            delay=$((delay * 2))
            [ $delay -gt 1800 ] && delay=1800   # cap at 30 minutes
            attempt=$((attempt + 1))
        else
            echo "❌ Failed with non-retryable error (exit code $status)."
            break
        fi
    done
  done



echo "✅ Done. Images saved in $ASSETS_DIR/00, $ASSETS_DIR/01, …"

