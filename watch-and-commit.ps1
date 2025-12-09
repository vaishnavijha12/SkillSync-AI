param(
    [string]$Path = ".",
    [int]$Interval = 5
)

Set-Location $Path

if (-not (Test-Path ".git")) {
    Write-Host "Not a git repository. Run 'git init' first." -ForegroundColor Red
    exit 1
}

function Get-Snapshot {
    Get-ChildItem -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "\\.git\\" } |
        ForEach-Object {
            [PSCustomObject]@{
                Path = $_.FullName
                Hash = (Get-FileHash $_.FullName -Algorithm MD5).Hash
            }
        }
}

$snap = Get-Snapshot

Write-Host "Watching $((Get-Location).Path) every $Interval seconds..." -ForegroundColor Cyan
Write-Host "Press CTRL + C to stop."

while ($true) {
    Start-Sleep -Seconds $Interval

    $newSnap = Get-Snapshot
    $changed = $false

    $newPaths = $newSnap.Path
    $oldPaths = $snap.Path

    # detect added or modified files
    foreach ($item in $newSnap) {
        if ($oldPaths -notcontains $item.Path) {
            $changed = $true
            break
        }

        $oldHash = ($snap | Where-Object { $_.Path -eq $item.Path }).Hash
        if ($oldHash -ne $item.Hash) {
            $changed = $true
            break
        }
    }

    # detect deleted files
    if (-not $changed) {
        foreach ($item in $snap) {
            if ($newPaths -notcontains $item.Path) {
                $changed = $true
                break
            }
        }
    }

    if ($changed) {
        try {
            git add -A
            $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            git commit -m "Auto commit at $time" --no-verify
            git push

            Write-Host "Committed and pushed at $time" -ForegroundColor Green
        }
        catch {
            Write-Host "Commit or push failed: $($_.Exception.Message)" -ForegroundColor Red
        }

        $snap = $newSnap
    }
}
