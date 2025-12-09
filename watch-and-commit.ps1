param(
    [string]$Path = ".",
    [int]$Interval = 5
)

Set-Location $Path

if (-not (Test-Path ".git")) {
    Write-Host "Not a git repository. Run 'git init' first." -ForegroundColor Red
    exit 1
}

# Directories (substrings) to ignore during recursive scan
$ignoreDirs = @('.git', 'node_modules', '.next', 'dist', 'build', '.venv', '.cache')

function IsIgnoredPath($fullPath) {
    foreach ($p in $ignoreDirs) {
        if ($fullPath -like "*$p*") { return $true }
    }
    return $false
}

function Safe-FileHash($filePath) {
    try {
        return (Get-FileHash -Path $filePath -Algorithm MD5 -ErrorAction Stop).Hash
    } catch {
        # Can't read file (locked/permission) — return null so caller can skip it
        return $null
    }
}

function Get-Snapshot {
    # Use Get-ChildItem but filter out ignored directories
    $files = Get-ChildItem -Recurse -File -Force -ErrorAction SilentlyContinue |
             Where-Object { -not (IsIgnoredPath($_.FullName)) }

    $result = @()
    foreach ($f in $files) {
        $h = Safe-FileHash($f.FullName)
        if ($h -ne $null) {
            $result += [PSCustomObject]@{ Path = $f.FullName; Hash = $h }
        } else {
            # skip locked/unreadable file silently
        }
    }
    return $result
}

$snap = Get-Snapshot

Write-Host "Watching $((Get-Location).Path) every $Interval seconds..." -ForegroundColor Cyan
Write-Host "Ignored directories: $($ignoreDirs -join ', ')" -ForegroundColor DarkCyan
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
            git commit -m "Auto commit at $time" --no-verify 2>$null
            # Attempt push; if it fails, show the error but keep running
            $push = git push 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Committed and pushed at $time" -ForegroundColor Green
            } else {
                Write-Host "Committed at $time but push failed:" -ForegroundColor Yellow
                Write-Host $push
            }
        }
        catch {
            Write-Host "Commit failed: $($_.Exception.Message)" -ForegroundColor Red
        }

        $snap = $newSnap
    }
}
