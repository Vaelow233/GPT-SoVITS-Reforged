<#
.SYNOPSIS
Run a Python tool in the selected uv environment, from the project root.
.EXAMPLE
./run-tool.ps1 -Device cpu -Script tools/uvr5/webui.py -ScriptArguments @('cpu', 'False', '9873', 'False')
.EXAMPLE
./run-tool.ps1 -Device cpu -Script tools/asr/funasr_asr.py -ScriptArguments @('-i', 'input', '-o', 'output/asr', '-l', 'zh')
#>
[CmdletBinding()]
param(
    [ValidateSet('cu126', 'cu128', 'cpu')][string]$Device = 'cu128',
    [Parameter(Mandatory = $true)][string]$Script,
    [string[]]$ScriptArguments = @()
)

$ErrorActionPreference = 'Stop'
$previousEnvironment = $env:UV_PROJECT_ENVIRONMENT
$previousPythonPath = $env:PYTHONPATH
. "$PSScriptRoot/tools/uv-common.ps1"
try {
    Initialize-UvProject -Device $Device
    Push-Location $PSScriptRoot
    try {
        if (-not (Test-Path -LiteralPath $Script -PathType Leaf)) { throw "Script not found: $Script" }
        Invoke-Checked uv (@('run', '--locked', '--extra', $Device.ToLowerInvariant(), 'python', $Script) + $ScriptArguments)
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
