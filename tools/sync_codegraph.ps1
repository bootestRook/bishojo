param(
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Keep this file ASCII-only so Windows PowerShell 5.1 can parse it from Git hooks.
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [System.Text.UTF8Encoding]::new()

function Write-CodeGraphMessage {
    param([string]$Message)

    if (-not $Quiet) {
        Write-Host $Message
    }
}

$codegraphCommand = Get-Command codegraph -ErrorAction SilentlyContinue
if ($null -eq $codegraphCommand) {
    Write-CodeGraphMessage 'CodeGraph was not found in PATH; skipping index sync.'
    exit 0
}

$repoRoot = (& git rev-parse --show-toplevel 2>$null).Trim()
if ([string]::IsNullOrWhiteSpace($repoRoot)) {
    Write-CodeGraphMessage 'Cannot find Git repository root; skipping CodeGraph index sync.'
    exit 0
}

Push-Location $repoRoot
try {
    $dbPath = Join-Path $repoRoot '.codegraph/codegraph.db'
    if (Test-Path -LiteralPath $dbPath -PathType Leaf) {
        & codegraph sync -q $repoRoot
    } else {
        Write-CodeGraphMessage 'Initializing CodeGraph index...'
        & codegraph init $repoRoot
    }

    if ($LASTEXITCODE -ne 0) {
        Write-CodeGraphMessage 'CodeGraph index sync failed; Git operation will continue.'
        exit 0
    }

    Write-CodeGraphMessage 'CodeGraph index is ready.'
} finally {
    Pop-Location
}

exit 0
