Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Git does not automatically enable tracked hooks. Keep this file ASCII-only for Windows PowerShell 5.1.
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [System.Text.UTF8Encoding]::new()

$repoRoot = (& git rev-parse --show-toplevel).Trim()
if ([string]::IsNullOrWhiteSpace($repoRoot)) {
    throw 'Cannot find Git repository root.'
}

Push-Location $repoRoot
try {
    git config core.hooksPath .githooks
    Write-Host 'Git hooks enabled: core.hooksPath=.githooks'
} finally {
    Pop-Location
}
