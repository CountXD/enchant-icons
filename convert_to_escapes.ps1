# Convert ONLY color codes and icons to escape sequences
# Keeps all other text (translated names) as proper UTF-8 characters

$ProjectDir = "c:\Users\Emerson\.gemini\antigravity\scratch\mc-project\enchant-icons\assets\minecraft\lang"

$totalFiles = 0

# Get all JSON files in project directory
$projectFiles = Get-ChildItem -Path $ProjectDir -Filter "*.json"

foreach ($file in $projectFiles) {
    $projectFile = $file.FullName
    
    try {
        # Read file content as raw text
        $content = Get-Content -Path $projectFile -Raw -Encoding UTF8
        
        # Parse JSON
        $data = $content | ConvertFrom-Json
        
        # Build output with proper escaping (only for color/icons)
        $lines = @()
        $lines += "{"
        
        $props = $data.PSObject.Properties | ForEach-Object { $_ }
        for ($i = 0; $i -lt $props.Count; $i++) {
            $prop = $props[$i]
            $key = $prop.Name
            $value = $prop.Value
            
            # Convert only specific characters to escape sequence
            $escapedValue = ""
            foreach ($char in $value.ToCharArray()) {
                $code = [int]$char
                
                # Section sign (§) for color codes - U+00A7
                if ($code -eq 0x00A7) {
                    $escapedValue += "\u00a7"
                }
                # Private Use Area characters (icons) - U+E000 to U+F8FF
                elseif ($code -ge 0xE000 -and $code -le 0xF8FF) {
                    $escapedValue += "\u{0:x4}" -f $code
                }
                # Backslash needs escaping in JSON
                elseif ($char -eq '\') {
                    $escapedValue += "\\"
                }
                # Double quote needs escaping in JSON
                elseif ($char -eq '"') {
                    $escapedValue += '\"'
                }
                # Newline
                elseif ($char -eq "`n") {
                    $escapedValue += "\n"
                }
                # Carriage return
                elseif ($char -eq "`r") {
                    $escapedValue += "\r"
                }
                # Tab
                elseif ($char -eq "`t") {
                    $escapedValue += "\t"
                }
                # All other characters stay as-is (including translated text)
                else {
                    $escapedValue += $char
                }
            }
            
            # Add comma except for last item
            $comma = if ($i -lt $props.Count - 1) { "," } else { "" }
            $lines += "  `"$key`": `"$escapedValue`"$comma"
        }
        
        $lines += "}"
        
        $output = $lines -join "`r`n"
        
        # Write file with UTF-8 encoding (no BOM)
        [System.IO.File]::WriteAllText($projectFile, $output, [System.Text.UTF8Encoding]::new($false))
        
        Write-Host "Converted $($file.Name)"
        $totalFiles++
    }
    catch {
        Write-Host "Error processing $($file.Name): $_"
    }
}

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "Files converted: $totalFiles"
