fail() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }
require_command() { command -v "$1" >/dev/null 2>&1 || fail "$1 is required on PATH. Install it first."; }
require_value() { [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || fail "Missing value for $1"; }

initialize_uv_project() {
    local device="$1"
    case "$device" in cu126|cu128|cpu) ;; *) fail "Invalid device: $device (supported: cu126, cu128, cpu)." ;; esac
    [[ "$(uname -s)" == Linux && "$(uname -m)" == x86_64 ]] || fail 'Only Linux x86_64 is supported by this lockfile.'
    [[ -f "$ROOT/pyproject.toml" && -f "$ROOT/uv.lock" ]] || fail 'pyproject.toml and uv.lock are required.'
    require_command uv
    require_command ffmpeg
    export PYTHONPATH="$ROOT:$ROOT/GPT_SoVITS/BigVGAN:$ROOT/tools:$ROOT/tools/asr:$ROOT/GPT_SoVITS:$ROOT/tools/uvr5${PYTHONPATH:+:$PYTHONPATH}"
    export UV_PROJECT_ENVIRONMENT="${UV_PROJECT_ENVIRONMENT:-$ROOT/.venv-$device}"
    if [[ "$UV_PROJECT_ENVIRONMENT" != /* ]]; then
        export UV_PROJECT_ENVIRONMENT="$ROOT/$UV_PROJECT_ENVIRONMENT"
    fi
    printf '[BACKEND] %s\n[ENV] %s\n' "$device" "$UV_PROJECT_ENVIRONMENT"
}
