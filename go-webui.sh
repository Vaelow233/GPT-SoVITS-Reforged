#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/tools/uv-common.sh"

device=cu128
language=zh_CN
while (($#)); do
    case "$1" in
        --device) require_value "$@"; device="${2,,}"; shift 2 ;;
        --language) require_value "$@"; language="$2"; shift 2 ;;
        -h|--help)
            echo 'Usage: bash go-webui.sh [--device cu126|cu128|cpu] [--language zh_CN]'
            echo 'Defaults: cu128, zh_CN. Uses the same environment as install.sh.'
            exit 0 ;;
        *) fail "Unknown argument: $1. See --help." ;;
    esac
done

initialize_uv_project "$device"
cd "$ROOT"
exec uv run --locked --extra "$device" python webui.py "$language"
