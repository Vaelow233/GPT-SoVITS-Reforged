#!/usr/bin/env bash
set -euo pipefail

cd /workspace/GPT-SoVITS

download_resources() {
    local args=(--source "${MODEL_SOURCE:-ModelScope}")
    case "${DOWNLOAD_UVR5:-false}" in
        true) args+=(--download-uvr5) ;;
        false) ;;
        *) echo 'DOWNLOAD_UVR5 must be true or false.' >&2; exit 1 ;;
    esac
    python tools/install_resources.py "${args[@]}" "$@"
}

if [[ "${GPT_SOVITS_DEVICE:-cu128}" == cpu ]]; then
    export is_half=false
fi

case "${1:-webui}" in
    webui)
        if (($#)); then shift; fi
        case "${DOWNLOAD_MODELS:-true}" in
            true) download_resources ;;
            false) ;;
            *) echo 'DOWNLOAD_MODELS must be true or false.' >&2; exit 1 ;;
        esac
        exec python webui.py "${WEBUI_LANGUAGE:-zh_CN}" "$@"
        ;;
    download-models)
        shift
        download_resources "$@"
        ;;
    *) exec "$@" ;;
esac
