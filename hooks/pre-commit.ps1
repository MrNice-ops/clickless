# pre-commit.ps1
# Runs before every commit. Scans the changes about to be committed for
# secrets and personal information, and blocks the commit if any are found. 

# If gitleaks can't be found, block the commit rather than skip the scan. 
if (-not (Get-Command gitleaks -ErrorAction SilentlyContinue)) {
    Write-Host 'Commit blocked: gitleaks is not installed or not on PATH.' -ForegroundColor Red
    exit 1
}

$gitleaksArgs = @('git', '--pre-commit', '--staged', '--redact', '--no-banner', '--verbose')

#Private rules (your email, phone, etc.) Live in a file git ignores. 
$personalRules = Join-Path $PSScriptRoot '..\gitleaks.personal.toml'
if (Test-Path $personalRules) {
    $gitleaksArgs += @('--config', $personalRules)
}

gitleaks @gitleaksArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Commit blocked: gitleaks found something that looks private (see above).' -ForegroundColor Red
    exit 1
}