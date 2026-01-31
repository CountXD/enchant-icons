# Fix Corrupted Language Files
# This script reads language files from the project and backup directories,
# then merges the color codes/icons from the project with the correct translations from the backup.

$ProjectDir = "c:\Users\Emerson\.gemini\antigravity\scratch\mc-project\enchant-icons\assets\minecraft\lang"
$BackupDir = "C:\Users\Emerson\Downloads\InventivetalentDev minecraft-assets 1.21.11 assets-minecraft_lang"

$totalChanges = 0
$filesFixed = 0
$filesSkipped = 0

function Get-Prefix {
    param([string]$value)
    
    # The prefix pattern is: color code (§X) + icon char(s) + optional space
    # Color code is § (char 167) followed by a hex digit or letter
    # Icon chars are in the private use area (U+E000-U+FFFF)
    
    $prefix = ""
    $i = 0
    
    # Check for color code (§ followed by format char)
    if ($value.Length -ge 2 -and [int]$value[0] -eq 167) {
        $prefix = $value.Substring(0, 2)
        $i = 2
    }
    
    # Consume any private use area characters (icons)
    while ($i -lt $value.Length) {
        $charCode = [int]$value[$i]
        if ($charCode -ge 0xE000 -and $charCode -le 0xFFFF) {
            $prefix += $value[$i]
            $i++
        }
        else {
            break
        }
    }
    
    # Include trailing space if present
    if ($i -lt $value.Length -and $value[$i] -eq ' ') {
        $prefix += ' '
    }
    
    return $prefix
}

# Get all JSON files in project directory
$projectFiles = Get-ChildItem -Path $ProjectDir -Filter "*.json"

foreach ($file in $projectFiles) {
    $projectFile = $file.FullName
    $backupFile = Join-Path $BackupDir $file.Name
    
    # Check if backup file exists
    if (-not (Test-Path $backupFile)) {
        Write-Host "Skipped $($file.Name): No backup file found"
        $filesSkipped++
        continue
    }
    
    try {
        # Read project file
        $projectContent = Get-Content -Path $projectFile -Raw -Encoding UTF8
        $projectData = $projectContent | ConvertFrom-Json
        
        # Read backup file
        $backupContent = Get-Content -Path $backupFile -Raw -Encoding UTF8
        $backupData = $backupContent | ConvertFrom-Json
        
        $changesInFile = 0
        
        # Process each property in the project file
        $fixedData = [ordered]@{}
        
        foreach ($prop in $projectData.PSObject.Properties) {
            $key = $prop.Name
            $value = $prop.Value
            
            if ($key -like "enchantment.minecraft.*") {
                # Extract prefix (color code + icon + space)
                $prefix = Get-Prefix $value
                
                # Get correct name from backup
                $backupValue = $backupData.$key
                if ($backupValue) {
                    $fixedValue = $prefix + $backupValue
                    $fixedData[$key] = $fixedValue
                    if ($fixedValue -ne $value) {
                        $changesInFile++
                    }
                }
                else {
                    $fixedData[$key] = $value
                }
            }
            else {
                $fixedData[$key] = $value
            }
        }
        
        if ($changesInFile -gt 0) {
            # Convert to JSON and save
            $jsonOutput = $fixedData | ConvertTo-Json -Depth 10
            # Use .NET to write with UTF-8 without BOM
            [System.IO.File]::WriteAllText($projectFile, $jsonOutput, [System.Text.UTF8Encoding]::new($false))
            
            Write-Host "Fixed $($file.Name): $changesInFile changes made"
            $totalChanges += $changesInFile
            $filesFixed++
        }
        else {
            Write-Host "Checked $($file.Name): No changes needed"
        }
    }
    catch {
        Write-Host "Error processing $($file.Name): $_"
        $filesSkipped++
    }
}

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "Files fixed: $filesFixed"
Write-Host "Files skipped: $filesSkipped"
Write-Host "Total changes: $totalChanges"
