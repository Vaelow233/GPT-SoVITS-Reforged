#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/tools/uv-common.sh"
device=cu128
while (($#)); do
    case "$1" in
        --device) require_value "$@"; device="${2,,}"; shift 2 ;;
        --) shift; break ;;
        -h|--help)
            echo 'Usage: bash run-tool.sh [--device cu126|cu128|cpu] -- SCRIPT [SCRIPT_ARGUMENTS...]'
            echo 'Paths are relative to the project root. Default backend: cu128.'
            exit 0 ;;
        *) fail 'Use -- before the Python script and its arguments.' ;;
    esac
done
[[ $# -gt 0 ]] || fail 'A Python script is required. See --help.'
initialize_uv_project "$device"
cd "$ROOT"
[[ -f "$1" ]] || fail "Script not found: $1"
exec uv run --locked --extra "$device" python "$@"
