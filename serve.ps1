# Auto-generate recipes/index.json from all .json files in /recipes/
$recipes = Get-ChildItem -Path "recipes" -Filter "*.json" |
    Where-Object { $_.Name -ne "index.json" -and $_.Name -ne "_template.json" } |
    Sort-Object Name |
    ForEach-Object { $_.BaseName }

$json = ConvertTo-Json @($recipes)
[System.IO.File]::WriteAllText(
    (Join-Path $PWD "recipes/index.json"),
    $json,
    [System.Text.Encoding]::UTF8
)
Write-Host "  recipes/index.json updated - $($recipes.Count) recipes found" -ForegroundColor Green

# Kill anything already running on port 8000
$conn = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue
if ($conn) {
    Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 300
}

Write-Host ""
Write-Host "  The Weekly Plate" -ForegroundColor DarkYellow
Write-Host "  http://localhost:8000" -ForegroundColor Cyan
Write-Host "  Press Ctrl+C to stop."
Write-Host ""

# Open browser after 1s (gives server time to start)
Start-Job { Start-Sleep 1; Start-Process 'http://localhost:8000' } | Out-Null

python -m http.server 8000
