#!/usr/bin/env bash
set -euo pipefail

ASSETS_DIR="assets"
YOUCOOK_DIR="$ASSETS_DIR/youcook2"
YOUCOOK_DIR_TMP="$ASSETS_DIR/tmp"
RAW_VIDEOS_URL="https://prism.eecs.umich.edu/natlouis/youcook2/raw_videos.partaa"
# NOTE: This archive is hugh (144Gb) its better to use one of its 12 splits
# going down to around 12 GB
# For more info see: http://youcook2.eecs.umich.edu/download
# RAW_VIDEOS_URL="https://prism.eecs.umich.edu/natlouis/youcook2/raw_videos.tar.gz"

RAW_ARCHIVE="$YOUCOOK_DIR/raw_videos.tar.gz"
TMP_ARCHIVE="${RAW_ARCHIVE}.part"

mkdir -p "$YOUCOOK_DIR"

# ----------------------------------------
# Functions
# ----------------------------------------

download_archive() {
    echo "📥 Downloading archive (resume supported)..."
    wget --tries=20 --retry-connrefused --no-check-certificate -c \
         -O "$TMP_ARCHIVE" "$RAW_VIDEOS_URL"
    mv "$TMP_ARCHIVE" "$RAW_ARCHIVE"
}

verify_archive() {
    echo "🟡 Archive already exists, verifying..."
    if ! tar -tf "$RAW_ARCHIVE" >/dev/null 2>&1; then
        echo "❌ Archive appears corrupted. Resuming download..."
        mv "$RAW_ARCHIVE" "$TMP_ARCHIVE"
        download_archive
    else
        echo "✅ Archive looks OK"
    fi
}

extract_all() {
    local archive="$1"

    echo "⚙️ Extracting all videos (resumable)..."

    tar -xf "$archive" -C "$YOUCOOK_DIR" \
        --strip-components=1 \
        --checkpoint=.1000 \
        --ignore-zeros \
        --warning=no-unknown-keyword \
        --keep-old-files || true

    echo
    echo "ℹ️ tar: Unexpected EOF in archive is expected! (Because the dataset is incomplete anyways)"
    echo "✅ Extraction completed!"
}

main() {
    echo "📂 Downloading YouCook2 raw videos..."

    if [[ ! -f "$RAW_ARCHIVE" ]]; then
        download_archive
    else
        verify_archive
    fi

    # Extract a small subset (you can adjust this or remove for full extraction)
    extract_all "$RAW_ARCHIVE"
}

main "$@"

