#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/tools/uv-common.sh"

usage() {
    cat <<'EOF'
Usage: bash install.sh [--device cu126|cu128|cpu] [--source HF|HF-Mirror|ModelScope]
                       [--download-uvr5] [--skip-models] [--force]
Defaults: --device cu128 --source ModelScope
Requires uv, ffmpeg, cmake and (for model downloads) curl on PATH.
Uses Python 3.11 and uv.lock. System dependencies are checked, never installed.
EOF
}

device=cu128
source_name=ModelScope
download_args=()
skip_models=false
while (($#)); do
    case "$1" in
        --device) require_value "$@"; device="${2,,}"; shift 2 ;;
        --source) require_value "$@"; source_name="$2"; shift 2 ;;
        --download-uvr5) download_args+=(--download-uvr5); shift ;;
        --force) download_args+=(--force); shift ;;
        --skip-models) skip_models=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) fail "Unknown argument: $1. See --help." ;;
    esac
done
case "${source_name,,}" in
    hf) source_name=HF ;;
    hf-mirror) source_name=HF-Mirror ;;
    modelscope) source_name=ModelScope ;;
    *) fail "Invalid source: $source_name" ;;
esac

initialize_uv_project "$device"
require_command cmake
ffmpeg -version
cmake --version
if ! "$skip_models"; then require_command curl; fi

cd "$ROOT"
uv sync --locked --extra "$device"
if ! "$skip_models"; then
    uv run --no-sync --extra "$device" python tools/install_resources.py \
        --source "$source_name" "${download_args[@]}"
fi
printf '[DONE] Start with: bash go-webui.sh --device %s\n' "$device"
