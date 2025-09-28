#!/usr/bin/env bash
set -euo pipefail

ASSETS_DIR="assets/openimages"
TSV_FILE="$ASSETS_DIR/open-images-dataset-train0.tsv"
LIMIT=10000   # total images to fetch
PER_FOLDER=1000

mkdir -p "$ASSETS_DIR"

# -------------------------------
# Helpers
# -------------------------------

download_tsv() {
    local tmp_file="${TSV_FILE}.part"

    # If final file doesn't exist, resume or start download into .part
    if [[ ! -f "$TSV_FILE" ]]; then
        echo "📂 Downloading Open Images train0.tsv..."

        wget -c \
          --show-progress \
          -O "$tmp_file" \
          "https://storage.googleapis.com/cvdf-datasets/oid/open-images-dataset-train0.tsv"

        # Move only once download finished
        mv "$tmp_file" "$TSV_FILE"
    fi
}

download_with_retry() {
    local url="$1"
    local outfile="$2"

    local delay=2
    local attempt=1

    while true; do
        if wget -c -O "$outfile" "$url" 2> >(tee err.log >&2); then
            return 0   # success
        fi

        local status=$?
        if grep -q "429 Too Many Requests" err.log; then
            echo "⚠️ Attempt $attempt: got 429. Retrying in $delay seconds..."
            sleep "$delay"
            delay=$((delay * 2))
            (( delay > 1800 )) && delay=1800   # cap backoff at 30 min
            attempt=$((attempt + 1))
        else
            echo "❌ Failed with non-retryable error (exit code $status). Skipping..."
            return 0 # "Success"
        fi
    done
}

process_entry() {
    local lineno="$1"
    local url="$2"

    local folder
    folder=$(printf "%02d" $(((lineno-1)/PER_FOLDER)))
    mkdir -p "$ASSETS_DIR/$folder"

    local outfile="$ASSETS_DIR/$folder/${lineno}.jpg"

    if [[ -f "$outfile" ]]; then
        echo "⏭️ [$lineno/$LIMIT] Skipping $outfile (already exists)"
        return 0
    fi

    echo "📥 [$lineno/$LIMIT] → saving to $outfile"
    download_with_retry "$url" "$outfile" || return 1
}

main() {
    echo "⚙️ Downloading $LIMIT images into folders of $PER_FOLDER..."
    download_tsv

    echo "Works 1"
    count=0
    while IFS=$'\t' read -r url _; do
        count=$((count+1))
        process_entry "$count" "$url"
        [[ $count -ge $LIMIT ]] && break
    done < <(tail -n +2 "$TSV_FILE")

    echo "✅ Done. Images saved in $ASSETS_DIR/00, $ASSETS_DIR/01, …"
}

main "$@"

