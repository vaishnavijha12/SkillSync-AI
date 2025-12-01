# Auto commit + push loop every 5 minutes

Set-Location $PSScriptRoot

while ($true) {
    git add -A

    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        git commit -m "Auto commit $time"
        git push
        Write-Host "[Auto Commit] Changes pushed at $time"
    }
    else {
        Write-Host "[No Changes] Nothing to commit at $(Get-Date -Format 'HH:mm:ss')"
    }

    Start-Sleep -Seconds 300   # 5 minutes
}
