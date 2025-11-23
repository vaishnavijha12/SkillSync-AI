Write-Host "[AUTO PUSH STARTED]"

while ($true) {
    $status = git status --porcelain

    if (-not [string]::IsNullOrWhiteSpace($status)) {
        git add .
        git commit -m "Auto update $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        git push
        Write-Host "[PUSHED] $(Get-Date)"
    }
    else {
        Write-Host "[NO CHANGES] $(Get-Date)"
    }

    Start-Sleep -Seconds 30
}
