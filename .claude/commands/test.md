---
allowed-tools: Bash, Read, Glob
description: Run GUT unit tests and report results
---

Run the GUT unit tests for this project.

## Steps

1. **Load local config** (if exists):
   ```bash
   if [ -f ".claude/config.local" ]; then
     source .claude/config.local
   fi
   ```

2. **Find Godot executable** (if not configured):
   ```bash
   if [ -z "$GODOT" ]; then
     # Try PATH first
     GODOT=$(command -v godot 2>/dev/null)

     # Fallback: search common locations
     if [ -z "$GODOT" ]; then
       for dir in ~/godot ~/Applications /opt/godot /usr/local/bin ~/.local/share/godot; do
         found=$(find "$dir" -maxdepth 3 -name "Godot_v4*" -type f -executable 2>/dev/null | head -1)
         if [ -n "$found" ]; then
           GODOT="$found"
           break
         fi
       done
     fi
   fi

   if [ -z "$GODOT" ]; then
     echo "Error: Godot not found."
     echo "Either:"
     echo "  1. Add 'godot' to your PATH"
     echo "  2. Set GODOT=/path/to/godot in .claude/config.local"
     exit 1
   fi
   ```

3. **Execute tests**: `$GODOT --headless -s addons/gut/gut_cmdln.gd`

4. **Parse the output** and summarize:
   - Total tests run
   - Passed / Failed / Pending
   - If failures: show which tests failed and why

5. If all tests pass, confirm success

6. If tests fail, suggest fixes based on the error messages

## Test Subsets

To run specific test directories:
```bash
# Unit tests only
$GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit/

# Integration tests only
$GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/integration/

# Specific test file
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_example.gd
```
