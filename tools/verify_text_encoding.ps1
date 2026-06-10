param(
    [switch]$Staged
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Repository encoding gate. Keep this file ASCII-only so Windows PowerShell 5.1 can parse it as UTF-8-without-BOM bytes.
$StrictUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [System.Text.UTF8Encoding]::new()

function Invoke-GitUtf8 {
    param([string[]]$Arguments)

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = 'git'
    $startInfo.Arguments = $Arguments -join ' '
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.StandardOutputEncoding = $StrictUtf8
    $startInfo.StandardErrorEncoding = $StrictUtf8

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    $exitCode = $null

    try {
        [void]$process.Start()
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        $exitCode = $process.ExitCode
    } finally {
        $process.Dispose()
    }

    if ($exitCode -ne 0) {
        throw ("git {0} failed with exit code {1}: {2}" -f ($Arguments -join ' '), $exitCode, $stderr.Trim())
    }

    return $stdout
}

function Split-NulSeparatedOutput {
    param([string]$Text)

    if ([string]::IsNullOrEmpty($Text)) {
        return @()
    }

    return $Text.Split([char[]]@([char]0), [System.StringSplitOptions]::RemoveEmptyEntries)
}

function Test-HasSuspiciousMarker {
    param([string]$Text)

    $markers = @(
        ([string][char]0xFFFD),
        ([string]::Concat([char]0x951F, [char]0x65A4, [char]0x62F7)),
        ([string]::Concat([char]0x00EF, [char]0x00BB, [char]0x00BF))
    )

    foreach ($marker in $markers) {
        if ($Text.Contains($marker)) {
            return $true
        }
    }

    return $false
}

function Get-RepoRoot {
    $root = (Invoke-GitUtf8 @('rev-parse', '--show-toplevel')).Trim()
    if ([string]::IsNullOrWhiteSpace($root)) {
        throw 'Cannot find Git repository root.'
    }
    return $root
}

function Test-IsTextPath {
    param([string]$Path)

    $fileName = [System.IO.Path]::GetFileName($Path)
    $extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()

    $textFileNames = @(
        '.editorconfig',
        '.gitattributes',
        '.gitignore',
        'AGENTS.md',
        'README.md'
    )

    $textExtensions = @(
        '.bat',
        '.cfg',
        '.cmd',
        '.cs',
        '.css',
        '.gd',
        '.gitattributes',
        '.gitignore',
        '.godot',
        '.html',
        '.import',
        '.ini',
        '.js',
        '.json',
        '.md',
        '.ps1',
        '.sh',
        '.svg',
        '.toml',
        '.ts',
        '.txt',
        '.xml',
        '.yaml',
        '.yml'
    )

    return $textFileNames.Contains($fileName) -or $textExtensions.Contains($extension)
}

function Get-CandidatePaths {
    if ($Staged) {
        $output = Invoke-GitUtf8 @('-c', 'core.quotepath=false', 'diff', '--cached', '--name-only', '-z', '--diff-filter=ACMR')
    } else {
        $output = Invoke-GitUtf8 @('-c', 'core.quotepath=false', 'ls-files', '-z', '--cached', '--others', '--exclude-standard')
    }

    $paths = Split-NulSeparatedOutput -Text $output
    return $paths | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_) -and
        (Test-IsTextPath -Path $_)
    }
}

function Test-TextFileEncoding {
    param(
        [string]$RepoRoot,
        [string]$RelativePath
    )

    if (Test-HasSuspiciousMarker -Text $RelativePath) {
        return "${RelativePath}: suspicious mojibake marker found in file path."
    }

    $fullPath = Join-Path $RepoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        return $null
    }

    $bytes = [System.IO.File]::ReadAllBytes($fullPath)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return "${RelativePath}: UTF-8 BOM is not allowed. Save as UTF-8 without BOM."
    }

    try {
        $text = $StrictUtf8.GetString($bytes)
    } catch [System.Text.DecoderFallbackException] {
        return "${RelativePath}: invalid UTF-8 text."
    }

    if (Test-HasSuspiciousMarker -Text $text) {
        return "${RelativePath}: suspicious mojibake marker found."
    }

    return $null
}

$repoRoot = Get-RepoRoot
$failed = New-Object System.Collections.Generic.List[string]

foreach ($path in Get-CandidatePaths) {
    $result = Test-TextFileEncoding -RepoRoot $repoRoot -RelativePath $path
    if ($null -ne $result) {
        $failed.Add($result)
    }
}

if ($failed.Count -gt 0) {
    Write-Error ("UTF-8 encoding check failed:`n" + ($failed -join "`n"))
    exit 1
}

Write-Host 'UTF-8 encoding check passed.'
