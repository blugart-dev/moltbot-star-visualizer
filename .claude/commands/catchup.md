---
allowed-tools: Bash, Read, Glob
description: Read all files changed in current branch to restore context
---

Quickly restore context after `/clear` by reading all files changed in the current branch.

## Usage

```bash
/catchup              # Read all changed files vs main
/catchup --stat       # Just show summary, don't read files
```

## When to Use

- After running `/clear` to free up context
- When resuming work on a branch after a break
- At the start of a session on an existing branch

This is part of the "clear + catchup" workflow recommended by industry experts.

## Execution

1. **Check if on a feature branch**
   ```bash
   BRANCH=$(git branch --show-current)
   ```
   If on `main`, show:
   ```
   Already on main branch. Nothing to catch up on.
   Use /sync to see project status.
   ```

2. **Get list of changed files**
   ```bash
   git diff main --name-only
   ```

3. **If `--stat` flag, just show summary**
   ```bash
   git diff main --stat
   ```
   Then STOP.

4. **Filter to relevant files**
   Only read files that exist and are code/config:
   - `.gd` files (GDScript)
   - `.tscn` files (scenes)
   - `.tres` files (resources)
   - `.md` files (documentation)
   - `.json` files (config)

   Skip binary files, images, etc.

5. **Read each file**
   Use the Read tool to read each changed file.
   For large files (>500 lines), read first 100 lines + last 50 lines.

6. **Summarize**
   After reading, provide a brief summary:
   ```
   Caught up on X files changed in branch `feature/Y`:

   - scripts/units/base_unit.gd: Added retreat logic
   - scripts/core/constants.gd: New RETREAT_THRESHOLD constant
   - tests/unit/test_retreat.gd: New test file

   Ready to continue. What would you like to work on?
   ```

## Example

```
> /clear
Context cleared.

> /catchup
Reading 5 files changed in branch `feature/42-retreat-logic`...

Read: scripts/units/states/attack_state.gd (45 lines changed)
Read: scripts/core/constants.gd (3 lines added)
Read: tests/unit/test_attack_state.gd (new file, 89 lines)
...

Caught up on 5 files. Changes add retreat behavior when health < 20%.
Ready to continue.
```
