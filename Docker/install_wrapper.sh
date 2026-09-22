#!/usr/bin/env bash
set -euo pipefail

device="${1:-cu128}"
case "$device" in
    cpu|cu126|cu128) ;;
    *) echo "Unsupported DEVICE: $device (choose cpu, cu126 or cu128)." >&2; exit 1 ;;
esac

# Only dependency metadata is copied into this layer, models are installed at runtime
uv sync --locked --no-dev --extra "$device" --python /usr/local/bin/python3.11
