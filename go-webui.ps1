<#
.SYNOPSIS
Start the WebUI with a locked uv backend (default: cu128, zh_CN).
.EXAMPLE
./go-webui.ps1 -Device cpu -Language en_US
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('cu126', 'cu128', 'cpu')][string]$Device = 'cu128',
    [Parameter(Position = 1)][string]$Language = 'zh_CN'
)

$ErrorActionPreference = 'Stop'
$previousEnvironment = $env:UV_PROJECT_ENVIRONMENT
$previousPythonPath = $env:PYTHONPATH
. "$PSScriptRoot/tools/uv-common.ps1"

try {
    Initialize-UvProject -Device $Device
    Push-Location $PSScriptRoot
    try {
        Invoke-Checked uv @('run', '--locked', '--extra', $Device.ToLowerInvariant(),
            'python', 'webui.py', $Language)
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
