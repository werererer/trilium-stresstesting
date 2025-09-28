#!/usr/bin/env bash
set -euo pipefail

ASSETS_DIR="assets"
YOUCOOK_DIR="$ASSETS_DIR/youcook2"
RAW_VIDEOS_URL="https://prism.eecs.umich.edu/natlouis/youcook2/raw_videos.tar.gz"

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
    if ! tar -tzf "$RAW_ARCHIVE" >/dev/null 2>&1; then
        echo "❌ Archive appears corrupted. Resuming download..."
        mv "$RAW_ARCHIVE" "$TMP_ARCHIVE"
        download_archive
    else
        echo "✅ Archive looks OK"
    fi
}

extract_subset() {
    local archive="$1"
    local subset_count="$2"

    echo "⚙️ Extracting $subset_count videos for testing..."

    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' INT TERM EXIT

    # extract only the first N videos
    tar -tzf "$archive" | head -n "$subset_count" \
        | tar -xzf "$archive" -C "$tmp_dir" --strip-components=1 -T -

    rsync -a --ignore-existing "$tmp_dir/" "$YOUCOOK_DIR/"
    rm -rf "$tmp_dir"

    echo "✅ Extraction complete. Videos are under $YOUCOOK_DIR/"
}

main() {
    echo "📂 Downloading YouCook2 raw videos..."

    if [[ ! -f "$RAW_ARCHIVE" ]]; then
        download_archive
    else
        verify_archive
    fi

    # Extract a small subset (you can adjust this or remove for full extraction)
    extract_subset "$RAW_ARCHIVE" 20
}

main "$@"

