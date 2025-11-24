# Auto commit + push loop
# Run this from the SkillSync AI repo

# Always work in the folder where this script lives
Set-Location $PSScriptRoot

while ($true) {
    # Stage all changes
    git add -A

    # Check if there is anything staged
    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        # There ARE staged changes → make a commit
        $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $msg  = "Auto commit $time"
        git commit -m $msg
        git push
        Write-Host "[$time] Auto commit & push done." 
    } else {
        Write-Host "No changes to commit."
    }

    # Wait 2 minutes before next check
    Start-Sleep -Seconds 120
}
