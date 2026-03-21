param(
    [string]$VaultName,
    [string]$ParentDir
)

$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$RepoRoot  = (Resolve-Path -LiteralPath (Join-Path $ScriptDir "..")).Path

if (-not $VaultName) {
    $VaultName = (Read-Host "Vault name").Trim()
}
if (-not $VaultName) {
    Write-Error "Vault name cannot be empty."
    exit 1
}

if (-not $ParentDir) {
    $ParentDir = (Read-Host "Parent directory (leave blank for current directory)").Trim()
}
if (-not $ParentDir) {
    $ParentDir = (Get-Location).Path
}

$VaultRoot = Join-Path $ParentDir $VaultName

if (Test-Path -LiteralPath $VaultRoot) {
    Write-Error "Directory already exists: $VaultRoot"
    exit 1
}

New-Item -ItemType Directory -Path $VaultRoot -Force | Out-Null

$RuntimeDirs = @(
    "inbox", "notes", "facts", "metrics", "people",
    "sources", "clusters", "journal", "attachments",
    "private", "scratch", "cache", "temp", "exports", "archive"
)

foreach ($rel in $RuntimeDirs) {
    New-Item -ItemType Directory -Path (Join-Path $VaultRoot $rel) -Force | Out-Null
}

# Copy templates and prompts from repo
foreach ($src in @("templates", "prompts")) {
    $srcPath = Join-Path $RepoRoot $src
    $dstPath = Join-Path $VaultRoot $src
    if (Test-Path -LiteralPath $srcPath) {
        Copy-Item -LiteralPath $srcPath -Destination $dstPath -Recurse -Force
    }
}

# Copy CLAUDE_FOAM.md into vault as both CLAUDE.md and AGENTS.md
$claudeSrc = Join-Path $RepoRoot "CLAUDE_FOAM.md"
if (Test-Path -LiteralPath $claudeSrc) {
    Copy-Item -LiteralPath $claudeSrc -Destination (Join-Path $VaultRoot "CLAUDE.md")  -Force
    Copy-Item -LiteralPath $claudeSrc -Destination (Join-Path $VaultRoot "AGENTS.md") -Force
}

Write-Host "Vault '$VaultName' created at $VaultRoot"
