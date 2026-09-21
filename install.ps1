<#
.SYNOPSIS
Sync a uv environment and download model/language resources (Windows x64).
.EXAMPLE
./install.ps1 -Device cu128 -Source ModelScope -DownloadUVR5
.EXAMPLE
./install.ps1 -Device cpu -SkipModels
#>
[CmdletBinding()]
param(
    [ValidateSet('cu126', 'cu128', 'cpu')][string]$Device = 'cu128',
    [ValidateSet('HF', 'HF-Mirror', 'ModelScope')][string]$Source = 'ModelScope',
    [switch]$DownloadUVR5,
    [switch]$SkipModels,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$previousEnvironment = $env:UV_PROJECT_ENVIRONMENT
$previousPythonPath = $env:PYTHONPATH
. "$PSScriptRoot/tools/uv-common.ps1"

try {
    Initialize-UvProject -Device $Device -Installing
    Invoke-Checked ffmpeg @('-version')
    Invoke-Checked cmake @('--version')
    if (-not $SkipModels -and -not (Get-Command curl.exe -ErrorAction SilentlyContinue)) {
        throw 'curl.exe is required for model downloads. Install curl or use -SkipModels.'
    }

    Push-Location $PSScriptRoot
    try {
        $backend = $Device.ToLowerInvariant()
        $Source = switch ($Source.ToLowerInvariant()) {
            'hf' { 'HF' }
            'hf-mirror' { 'HF-Mirror' }
            'modelscope' { 'ModelScope' }
        }
        Invoke-Checked uv @('sync', '--locked', '--extra', $backend)
        if (-not $SkipModels) {
            $downloadArgs = @('run', '--no-sync', '--extra', $backend, 'python',
                'tools/install_resources.py', '--source', $Source)
            if ($DownloadUVR5) { $downloadArgs += '--download-uvr5' }
            if ($Force) { $downloadArgs += '--force' }
            Invoke-Checked uv $downloadArgs
        }
        Write-Host "[DONE] Start with: ./go-webui.ps1 -Device $backend"
    }
    finally { Pop-Location }
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    $env:UV_PROJECT_ENVIRONMENT = $previousEnvironment
    $env:PYTHONPATH = $previousPythonPath
}
