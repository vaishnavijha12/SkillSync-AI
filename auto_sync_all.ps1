# Auto commit + push changes for two repositories every 5 minutes

# Path to Repo 1 (SkillSync AI)
$repo1 = "C:\Users\profe\OneDrive\Desktop\SkillSync AI"

# Path to Repo 2 (fast-nextjs-v2)
$repo2 = "C:\Users\profe\OneDrive\Desktop\SkillSync AI\fast-nextjs-v2"

function Sync-Repo($path) {
    if (Test-Path $path) {
        Set-Location $path
        git add -A

        git diff --cached --quiet
        if ($LASTEXITCODE -ne 0) {
            $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            git commit -m "Auto commit $time"
            git push
            Write-Host "[PUSHED] $path at $time"
        } else {
            Write-Host "[NO CHANGES] $path at $(Get-Date -Format 'HH:mm:ss')"
        }
    } else {
        Write-Host "[ERROR] Path not found: $path"
    }
}

while ($true) {
    Sync-Repo $repo1
    Sync-Repo $repo2
    Start-Sleep -Seconds 300  # 5 minutes
}
