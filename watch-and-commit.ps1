# watch-and-commit.ps1
# Usage: .\watch-and-commit.ps1 -Path . -Interval 5

param(
    [string]$Path = ".",
    [int]$Interval = 5
)

Set-Location $Path

if (-not (Test-Path .git)) {
    Write-Error "Not a git repo. Run 'git init' first."
    exit 1
}

# compute initial snapshot
function Get-Snapshot {
    Get-ChildItem -Recurse -File -Force -ErrorAction SilentlyContinue |
      Where-Object { $_.FullName -notmatch "\\.git\\" } |
      Select-Object @{Name="Path";Expression={$_.FullName}}, @{Name="Hash";Expression={(Get-FileHash $_.FullName -Algorithm MD5).Hash}}
}

$snap = Get-Snapshot

Write-Host "Watching $((Get-Location).Path) — interval $Interval sec. Ctrl+C to stop."

while ($true) {
    Start-Sleep -Seconds $Interval
    $new = Get-Snapshot

    $joined = @{}
    foreach ($n in $new) { $joined[$n.Path] = $n.Hash }
    $changed = $false

    # check added/changed
    foreach ($k in $joined.Keys) {
        if (-not $snap.Path -contains $k) { $changed = $true; break }
        $old = ($snap | Where-Object { $_.Path -eq $k }).Hash
        if ($old -ne $joined[$k]) { $changed = $true; break }
    }
    # check deleted
    if (-not $changed) {
        foreach ($s in $snap) {
            if (-not $joined.ContainsKey($s.Path)) { $changed = $true; break }
        }
    }

    if ($changed) {
        try {
            git add -A
            $time = (Get-Date).ToString("s")
            git commit -m "Auto: $time" --no-verify 2>$null
            git push 2>$null
            Write-Host "Committed & pushed at $time"
        } catch {
            Write-Warning "Commit/push failed: $_"
        }
        $snap = $new
    }
}
