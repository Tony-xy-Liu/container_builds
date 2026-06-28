#!/bin/bash
# Run the redroid container: privileged (so it can mount binderfs), GPU host accel,
# persistent /data, ADB on localhost:5555.
# Usage: ./run.sh [image_tag]   (default redroid/redroid:12.0.0_64only_mindthegapps)
set -euo pipefail

IMAGE="${1:-redroid/redroid:12.0.0_64only_mindthegapps}"
NAME="${REDROID_NAME:-redroid}"
DATA="${REDROID_DATA:-$HOME/redroid/data}"
GPU_NODE="${REDROID_GPU_NODE:-/dev/dri/renderD128}"

mkdir -p "$DATA"
sudo modprobe binder_linux 2>/dev/null || true

# Replace any existing instance.
docker rm -f "$NAME" 2>/dev/null || true

docker run -d --name "$NAME" --privileged --restart unless-stopped \
    -v "$DATA:/data" \
    -p 5555:5555 \
    --device "$GPU_NODE:$GPU_NODE" \
    "$IMAGE" \
    androidboot.redroid_gpu_mode=host \
    androidboot.redroid_gpu_node="$GPU_NODE"

echo ">>> Started $NAME from $IMAGE"
echo ">>> adb connect localhost:5555"
