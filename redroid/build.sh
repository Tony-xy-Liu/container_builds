#!/bin/bash
# Build a redroid image with Google Play (MindTheGapps overlay) on the docker host.
# Usage: ./build.sh [android_version]   (default 12.0.0_64only)
set -euo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ANDROID="${1:-12.0.0_64only}"
WORK="${REDROID_WORK:-$HOME/redroid}"
SCRIPT_DIR="$WORK/redroid-script"

mkdir -p "$WORK"

# Vendored builder: ayasa520/redroid-script injects MindTheGapps via a plain COPY
# into the official redroid base — no AOSP rebuild.
if [ ! -d "$SCRIPT_DIR" ]; then
    git clone --depth 1 https://github.com/ayasa520/redroid-script "$SCRIPT_DIR"
else
    git -C "$SCRIPT_DIR" pull --ff-only || true
fi

# Deps: prefer apt packages (mira's system python is externally managed).
python3 -c 'import requests, tqdm' 2>/dev/null || {
    echo "Installing python deps (requests, tqdm) via apt..."
    sudo apt-get install -y python3-requests python3-tqdm
}

# binder is required; load the module (binderfs is mounted by the privileged container).
sudo modprobe binder_linux 2>/dev/null || true

cd "$SCRIPT_DIR"
echo ">>> Building redroid $ANDROID with MindTheGapps ..."
python3 redroid.py -a "$ANDROID" -mtg

echo ">>> Built image: redroid/redroid:${ANDROID}_mindthegapps"
echo ">>> Generated Dockerfile:"
cat "$SCRIPT_DIR/Dockerfile"
