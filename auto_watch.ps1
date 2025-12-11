$path = "C:\Users\profe\OneDrive\Desktop\SkillSync AI"
$filter = "*.*"

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $path
$watcher.Filter = $filter
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

Register-ObjectEvent $watcher Changed -Action {
    git -C $path add -A
    $msg = "Auto commit $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    git -C $path commit -m $msg
    git -C $path push
    Write-Host "Pushed: $msg"
}

while ($true) { Start-Sleep 1 }
