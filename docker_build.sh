#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
device=cu128
tag=

usage() {
    cat <<'EOF'
Usage: bash docker_build.sh [--device cpu|cu126|cu128] [--tag IMAGE:TAG]
Build a linux/amd64 image using Python 3.11 and uv.lock.
Defaults: --device cu128 --tag gpt-sovits-reforged:local-cu128
Models are downloaded when the WebUI starts, not during the build.
EOF
}

require_value() {
    [[ $# -ge 2 && -n "$2" && "$2" != -* ]] || {
        echo "Missing value for $1" >&2; exit 1;
    }
}

while (($#)); do
    case "$1" in
        --device) require_value "$@"; device="${2,,}"; shift 2 ;;
        --cuda)
            require_value "$@"
            case "$2" in
                12.6) device=cu126 ;;
                12.8) device=cu128 ;;
                *) echo 'Supported CUDA versions: 12.6, 12.8.' >&2; exit 1 ;;
            esac
            shift 2 ;;
        --tag) require_value "$@"; tag="$2"; shift 2 ;;
        --lite) echo 'All images now omit models at build time; remove --lite.' >&2; exit 1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1. See --help." >&2; exit 1 ;;
    esac
done

case "$device" in
    cpu|cu126|cu128) ;;
    *) echo "Unsupported device: $device (choose cpu, cu126 or cu128)." >&2; exit 1 ;;
esac
command -v docker >/dev/null 2>&1 || { echo 'Docker is required on PATH.' >&2; exit 1; }
exec docker build --platform linux/amd64 --build-arg "DEVICE=$device" \
    --tag "${tag:-gpt-sovits-reforged:local-$device}" "$ROOT"
