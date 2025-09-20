#!/usr/bin/env bash
set -euo pipefail

ASSETS_DIR="assets"
YOUCOOK_DIR="$ASSETS_DIR/youcook2"
mkdir -p "$YOUCOOK_DIR"

echo "📂 Downloading YouCook2 raw videos..."

RAW_VIDEOS_URL="https://prism.eecs.umich.edu/natlouis/youcook2/raw_videos.tar.gz"
RAW_ARCHIVE="$YOUCOOK_DIR/raw_videos.tar.gz"

# Download with resume support + retries
if [[ ! -f "$RAW_ARCHIVE" ]]; then
  echo "📥 Downloading archive..."
  wget --tries=20 --retry-connrefused -c --no-check-certificate \
       -O "$RAW_ARCHIVE" "$RAW_VIDEOS_URL"
else
  echo "🟡 Archive already exists, resuming/extracting..."
fi

echo "⚙️ Extracting videos (subset for testing)..."

# Temp dir for partial extraction
TMP_DIR=$(mktemp -d)
cleanup() {
    echo "⚠️ Interrupted. Cleaning up temp dir..."
    rm -rf "$TMP_DIR"
}
trap cleanup INT TERM

# Extract only the first 20 videos into temp dir
tar -tzf "$RAW_ARCHIVE" | head -n 20 \
  | tar -xzf "$RAW_ARCHIVE" -C "$TMP_DIR" --strip-components=1 -T -

# Move extracted files atomically once complete
rsync -a --ignore-existing "$TMP_DIR/" "$YOUCOOK_DIR/"
rm -rf "$TMP_DIR"

echo "✅ Done. Videos are under $YOUCOOK_DIR/"

