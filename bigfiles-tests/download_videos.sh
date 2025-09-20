#!/usr/bin/env bash
set -euo pipefail

ASSETS_DIR="assets"
YOUCOOK_DIR="$ASSETS_DIR/youcook2"
mkdir -p "$YOUCOOK_DIR"

echo "📂 Downloading YouCook2 raw videos..."

RAW_VIDEOS_URL="https://prism.eecs.umich.edu/natlouis/youcook2/raw_videos.tar.gz"
RAW_ARCHIVE="$YOUCOOK_DIR/raw_videos.tar.gz"

download_archive() {
  wget --tries=20 --retry-connrefused -c --no-check-certificate \
       -O "$RAW_ARCHIVE" "$RAW_VIDEOS_URL"
}

# If archive doesn’t exist or looks broken, (re)download
if [[ ! -f "$RAW_ARCHIVE" ]]; then
  echo "📥 Downloading archive..."
  download_archive
else
  echo "🟡 Archive already exists, verifying..."
  if ! tar -tzf "$RAW_ARCHIVE" >/dev/null 2>&1; then
    echo "❌ Archive appears corrupted. Restarting download..."
    rm -f "$RAW_ARCHIVE"
    download_archive
  fi
fi

echo "⚙️ Extracting videos (subset for testing)..."

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' INT TERM EXIT

# Extract only the first 20
tar -tzf "$RAW_ARCHIVE" | head -n 20 \
  | tar -xzf "$RAW_ARCHIVE" -C "$TMP_DIR" --strip-components=1 -T -

rsync -a --ignore-existing "$TMP_DIR/" "$YOUCOOK_DIR/"
rm -rf "$TMP_DIR"

echo "✅ Done. Videos are under $YOUCOOK_DIR/"

