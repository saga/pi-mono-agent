$ErrorActionPreference = "Stop"

# pi-mono upstream sync script
# Usage: .\sync-upstream.ps1

$UpstreamRepo = "https://github.com/badlogic/pi-mono.git"
$UpstreamBranch = "main"

Write-Host "=== Start syncing pi-mono upstream ===" -ForegroundColor Cyan

# 1. Check if upstream is configured
$upstreamExists = $false
$result = git remote get-url upstream 2>&1
if ($LASTEXITCODE -eq 0) {
    $upstreamExists = $true
}

if (-not $upstreamExists) {
    Write-Host "[1/6] Adding upstream remote..." -ForegroundColor Yellow
    git remote add upstream $UpstreamRepo
} else {
    Write-Host "[1/6] upstream exists, skip adding" -ForegroundColor Green
}

# 2. Fetch upstream
Write-Host "[2/6] Fetching upstream..." -ForegroundColor Yellow
git fetch upstream

# 3. Check current branch
$currentBranch = git branch --show-current
Write-Host "[3/6] Current branch: $currentBranch" -ForegroundColor Cyan

# 4. Check for uncommitted changes
$status = git status --porcelain
if ($status) {
    Write-Host "[!] Warning: uncommitted changes" -ForegroundColor Red
    Write-Host "Please commit or stash changes first" -ForegroundColor Yellow
    git status
    exit 1
}

# 5. Rebase
Write-Host "[4/6] Rebasing to upstream/$UpstreamBranch..." -ForegroundColor Yellow

git rebase "upstream/$UpstreamBranch"
$rebaseExitCode = $LASTEXITCODE

if ($rebaseExitCode -eq 0) {
    Write-Host "[+] rebase completed" -ForegroundColor Green

    # 6. Push changes
    Write-Host "[5/6] Pushing to origin..." -ForegroundColor Yellow
    git push --force-with-lease
    $pushExitCode = $LASTEXITCODE

    if ($pushExitCode -eq 0) {
        Write-Host "[+] push completed" -ForegroundColor Green
    } else {
        Write-Host "[!] push failed" -ForegroundColor Red
    }
} else {
    Write-Host "[!] rebase has conflicts" -ForegroundColor Red

    # Find conflict files
    $conflicts = git status --porcelain | Where-Object { $_ -match "^UU" }
    if ($conflicts) {
        Write-Host "Conflict files:" -ForegroundColor Yellow
        $conflicts | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    }

    Write-Host ""
    Write-Host "Resolve conflicts manually, then run:" -ForegroundColor Cyan
    Write-Host "  git add <conflict-files>" -ForegroundColor White
    Write-Host "  git rebase --continue" -ForegroundColor White
    Write-Host ""
    Write-Host "Or abort rebase:" -ForegroundColor Cyan
    Write-Host "  git rebase --abort" -ForegroundColor White

    exit 1
}

Write-Host ""
Write-Host "=== Sync completed ===" -ForegroundColor Cyan
$latestCommit = git log --oneline -1
Write-Host "Latest commit: $latestCommit" -ForegroundColor White
