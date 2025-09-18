#!/usr/bin/env bash
set -euo pipefail

ASSETS_DIR="assets"
YOUCOOK_DIR="$ASSETS_DIR/youcook2"
mkdir -p "$YOUCOOK_DIR"

echo "📂 Downloading YouCook2 raw videos..."

RAW_VIDEOS_URL="https://prism.eecs.umich.edu/natlouis/youcook2/raw_videos.tar.gz"
RAW_ARCHIVE="$YOUCOOK_DIR/raw_videos.tar.gz"

# Download with resume support
if [[ ! -f "$RAW_ARCHIVE" ]]; then
  wget -c --no-check-certificate -O "$RAW_ARCHIVE" "$RAW_VIDEOS_URL"
else
  echo "🟡 Archive already exists, resuming/extracting..."
fi

echo "⚙️ Extracting videos (subset for testing)..."

# Extract only the first 20 videos (adjust as needed)
tar -tzf "$RAW_ARCHIVE" | head -n 20 | tar -xzf "$RAW_ARCHIVE" -C "$YOUCOOK_DIR" --strip-components=1 -T -

echo "✅ Done. Videos are under $YOUCOOK_DIR/"

