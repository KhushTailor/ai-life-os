$files = Get-ChildItem -Path "C:\Users\khush\.gemini\antigravity\scratch\life_os\lib" -Recurse -Filter "*.dart"
foreach ($f in $files) {
    $content = Get-Content $f.FullName -Raw
    $newContent = $content -replace '\.withOpacity\(', '.withValues(alpha: '
    if ($content -ne $newContent) {
        Set-Content $f.FullName -Value $newContent -NoNewline
        Write-Host ("Fixed: " + $f.Name)
    }
}
