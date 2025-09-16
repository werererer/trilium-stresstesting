#!/usr/bin/env bash
set -euo pipefail

ASSETS_DIR="assets"
YOUCOOK_DIR="$ASSETS_DIR/youcook2"
IMAGES_DIR="$ASSETS_DIR/openimages"

mkdir -p "$YOUCOOK_DIR" "$IMAGES_DIR"

echo "📂 Downloading raw YouCook2 videos..."

# RAW_VIDEOS_URL="https://prism.eecs.umich.edu/natlouis/youcook2/raw_videos.tar.gz"
# Part A see: http://youcook2.eecs.umich.edu/download
RAW_VIDEOS_URL="https://prism.eecs.umich.edu/natlouis/youcook2/raw_videos.partaa"
RAW_ARCHIVE="$YOUCOOK_DIR/raw_videos.tar.gz"

if [[ ! -f "$RAW_ARCHIVE" ]]; then
  wget -c --no-check-certificate -O "$RAW_ARCHIVE" "$RAW_VIDEOS_URL"
else
  echo "🟡 raw videos archive already present"
fi

echo "⚙️ Extracting some videos (you may want to limit how many you extract)"

# Extract a subset (for example first N files) or all; here extracting first few to youcook2
tar -xzf "$RAW_ARCHIVE" -C "$YOUCOOK_DIR" --strip-components=1

echo "📂 Downloading images subset from Open Images..."

# --- images subset (as before) ---
CSV_URL="https://storage.googleapis.com/openimages/2018_04/train/train-images-boxable.csv"
CSV_FILE="$IMAGES_DIR/train-images-boxable.csv"

wget -nc -O "$CSV_FILE" "$CSV_URL"

head -n 101 "$CSV_FILE" | tail -n +2 | cut -d, -f1 | while read -r imgid; do
  url="https://storage.googleapis.com/openimages/2018_04/train/${imgid}.jpg"
  echo "⬇️  Downloading $imgid.jpg"
  wget -c -P "$IMAGES_DIR" "$url" || true
done

echo "✅ Done. Assets under $ASSETS_DIR/"

