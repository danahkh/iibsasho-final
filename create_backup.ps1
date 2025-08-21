# Backup Script

# Get current folder and backup folder path
$source = Get-Location
$backupDir = Join-Path $source "backups"

# Create backup folder if it doesn’t exist
if (!(Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

# Generate timestamped filename
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$backupFile = Join-Path $backupDir ("backup-" + $timestamp + ".zip")

# Get all files/folders EXCEPT the backup folder itself
$items = Get-ChildItem -Path $source -Recurse | 
    Where-Object { $_.FullName -notlike "$backupDir*" }

# Create ZIP
Compress-Archive -Path $items.FullName -DestinationPath $backupFile -Force

Write-Host "✅ Backup created: $backupFile"
