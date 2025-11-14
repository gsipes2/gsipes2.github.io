<#
.SYNOPSIS
    Render the Quarto site, stage the generated `docs/` folder, commit if changes exist, and push to origin/main.

.DESCRIPTION
    This script runs `quarto render`, then runs a safe git workflow to add and commit the generated
    `docs/` directory and push it to `origin main`.

.PARAMETER Force
    If provided, skip the interactive confirmation before pushing.

.PARAMETER CommitMessage
    Commit message to use when committing generated site. Defaults to a clear message.

.EXAMPLE
    # From project root
    .\scripts\publish_site.ps1

    # Force without prompt and custom message
    .\scripts\publish_site.ps1 -Force -CommitMessage "chore(site): update docs from local render"
#>

param(
    [switch]$Force,
    [string]$CommitMessage = "chore(site): update docs from local quarto render"
)

set -o pipefail

function Write-ErrAndExit {
    param($Message, $ExitCode = 1)
    Write-Error $Message
    exit $ExitCode
}

# Ensure git is available and we are inside a git repo
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-ErrAndExit "git is not installed or not on PATH. Install Git and try again."
}

$gitTop = git rev-parse --show-toplevel 2>$null
if ([string]::IsNullOrEmpty($gitTop)) {
    Write-ErrAndExit "This script must be run inside a git repository (or ensure git is on PATH)."
}

Set-Location -LiteralPath $gitTop

# Check Quarto
if (-not (Get-Command quarto -ErrorAction SilentlyContinue)) {
    Write-ErrAndExit "Quarto CLI not found on PATH. Install Quarto (https://quarto.org) and try again."
}

Write-Host "Rendering Quarto site (this may take a while)..." -ForegroundColor Cyan
try {
    quarto render 2>&1 | Write-Host
} catch {
    Write-ErrAndExit "quarto render failed. See output above for details." 2
}

Write-Host "Checking git status..." -ForegroundColor Cyan
git status

# Stage docs/
Write-Host "Staging docs/..." -ForegroundColor Cyan
git add docs

# Check whether there is anything to commit
$porcelain = git status --porcelain docs | Out-String
if ([string]::IsNullOrWhiteSpace($porcelain)) {
    Write-Host "No changes detected in docs/ — nothing to commit." -ForegroundColor Yellow
    exit 0
}

Write-Host "Committing changes..." -ForegroundColor Cyan
try {
    git commit -m "$CommitMessage"
} catch {
    Write-ErrAndExit "git commit failed. Confirm staged changes and try again." 3
}

if (-not $Force) {
    Write-Host "About to push to origin main. Review the commit above and confirm." -ForegroundColor Yellow
    $ans = Read-Host "Push to origin/main? (y/N)"
    if ($ans -ne 'y' -and $ans -ne 'Y') {
        Write-Host "Push aborted by user." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "Pushing to remote origin main..." -ForegroundColor Cyan
try {
    git push origin main
    Write-Host "Push completed." -ForegroundColor Green
} catch {
    Write-ErrAndExit "git push failed. Resolve remote issues and try again." 4
}

exit 0
