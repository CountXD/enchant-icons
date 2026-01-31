# Fix Corrupted Language Files
# This script reads language files from the project and backup directories,
# then merges the color codes/icons from the project with the correct translations from the backup.

import json
import os
import re

# Directories
PROJECT_DIR = r"c:\Users\Emerson\.gemini\antigravity\scratch\mc-project\enchant-icons\assets\minecraft\lang"
BACKUP_DIR = r"C:\Users\Emerson\Downloads\InventivetalentDev minecraft-assets 1.21.11 assets-minecraft_lang"

def extract_prefix(value):
    """
    Extract the color code + icon prefix from a value.
    Format: \u00a7X\uXXXX (color code + icon + space)
    Returns (prefix, rest) tuple
    """
    # Match color code (\u00a7 followed by a character) and optional icon (\ue... or \uf...)
    # The prefix ends with a space
    match = re.match(r'^(§[0-9a-fklmnor][\ue000-\uffff]* ?)', value)
    if match:
        return match.group(1), value[len(match.group(1)):]
    return '', value

def fix_language_file(project_file, backup_file):
    """
    Fix a single language file by replacing corrupted names with correct ones from backup.
    """
    # Read project file (with color codes/icons but corrupted names)
    with open(project_file, 'r', encoding='utf-8') as f:
        project_data = json.load(f)
    
    # Read backup file (with correct translations)
    with open(backup_file, 'r', encoding='utf-8') as f:
        backup_data = json.load(f)
    
    # Fix each enchantment entry
    fixed_data = {}
    changes_made = 0
    
    for key, value in project_data.items():
        if key.startswith('enchantment.minecraft.'):
            # Extract prefix (color code + icon)
            prefix, _ = extract_prefix(value)
            
            # Get the correct name from backup
            if key in backup_data:
                correct_name = backup_data[key]
                # Combine prefix with correct name
                if prefix:
                    fixed_value = prefix + correct_name
                else:
                    fixed_value = correct_name
                fixed_data[key] = fixed_value
                if fixed_value != value:
                    changes_made += 1
            else:
                # Key not found in backup, keep original
                fixed_data[key] = value
        else:
            # Non-enchantment entries, keep as-is
            fixed_data[key] = value
    
    # Write fixed file
    with open(project_file, 'w', encoding='utf-8') as f:
        json.dump(fixed_data, f, ensure_ascii=False, indent=2)
    
    return changes_made

def main():
    # Get list of language files in project directory
    project_files = [f for f in os.listdir(PROJECT_DIR) if f.endswith('.json')]
    
    total_changes = 0
    files_fixed = 0
    files_skipped = 0
    
    for filename in project_files:
        project_file = os.path.join(PROJECT_DIR, filename)
        backup_file = os.path.join(BACKUP_DIR, filename)
        
        # Check if backup file exists
        if not os.path.exists(backup_file):
            print(f"Skipped {filename}: No backup file found")
            files_skipped += 1
            continue
        
        try:
            changes = fix_language_file(project_file, backup_file)
            if changes > 0:
                print(f"Fixed {filename}: {changes} changes made")
                total_changes += changes
                files_fixed += 1
            else:
                print(f"Checked {filename}: No changes needed")
        except Exception as e:
            print(f"Error processing {filename}: {e}")
            files_skipped += 1
    
    print(f"\n=== Summary ===")
    print(f"Files fixed: {files_fixed}")
    print(f"Files skipped: {files_skipped}")
    print(f"Total changes: {total_changes}")

if __name__ == "__main__":
    main()
