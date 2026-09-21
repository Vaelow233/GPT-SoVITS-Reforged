function Invoke-Checked {
    param([string]$Command, [string[]]$Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Command failed (exit $LASTEXITCODE)."
    }
}

function Initialize-UvProject {
    param([string]$Device, [switch]$Installing)
    if ([Environment]::OSVersion.Platform -ne 'Win32NT' -or
        -not [Environment]::Is64BitOperatingSystem -or
        $env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or
        $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') {
        throw 'This entry point only supports Windows x64.'
    }
    $root = Split-Path $PSScriptRoot -Parent
    foreach ($file in @('pyproject.toml', 'uv.lock')) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $file) -PathType Leaf)) {
            throw "Missing $file in $root."
        }
    }
    $commands = @('uv', 'ffmpeg')
    if ($Installing) { $commands += 'cmake' }
    foreach ($command in $commands) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
            throw "$command is required on PATH. Install it before running this script."
        }
    }
    if (-not $env:UV_PROJECT_ENVIRONMENT) {
        $env:UV_PROJECT_ENVIRONMENT = Join-Path $root ".venv-$($Device.ToLowerInvariant())"
    }
    elseif (-not [IO.Path]::IsPathRooted($env:UV_PROJECT_ENVIRONMENT)) {
        $env:UV_PROJECT_ENVIRONMENT = [IO.Path]::GetFullPath((Join-Path $root $env:UV_PROJECT_ENVIRONMENT))
    }
    $importPaths = @($root, "$root/GPT_SoVITS/BigVGAN", "$root/tools",
        "$root/tools/asr", "$root/GPT_SoVITS", "$root/tools/uvr5")
    if ($env:PYTHONPATH) { $importPaths += $env:PYTHONPATH }
    $env:PYTHONPATH = $importPaths -join [IO.Path]::PathSeparator
    Write-Host "[BACKEND] $($Device.ToLowerInvariant())"
    Write-Host "[ENV] $env:UV_PROJECT_ENVIRONMENT"
}
