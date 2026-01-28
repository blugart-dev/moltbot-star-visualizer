---
allowed-tools: Bash
description: Finish work on a worktree and clean up
---

Complete work on a feature branch: run tests, merge PR, and clean up.

This command auto-detects the context:
- **Clone** (from `/clone`): Runs tests, merges PR, shows cleanup instructions
- **Simple branch** (from `/branch`): Runs tests, merges PR, deletes branch, returns to main

## Step 0: Detect Context

```bash
# Check for clone marker
if [ -f ".clone-info" ]; then
  echo "clone"
# Check for worktree (legacy, .git is a file)
elif [ -f ".git" ]; then
  echo "worktree"
else
  echo "simple"
fi
```

---

## Clone Flow

If `.clone-info` exists (from `/clone`):

### Safety Checks

1. **Read clone info**
   ```bash
   source .clone-info
   # Variables: source, created, feature
   ```

2. **Get branch name**
   ```bash
   git branch --show-current
   ```

3. **Check for uncommitted changes**
   ```bash
   git status --porcelain
   ```
   - If changes exist, show them and ask:
     "Clone has uncommitted changes:"
     <list changes>
     "Options:"
     "1. Commit first (run /commit)"
     "2. Discard changes and continue"
     "3. Cancel"
   - Require explicit choice

4. **Check for unpushed commits**
   ```bash
   git log origin/<branch>..<branch> --oneline 2>/dev/null
   ```
   - If commits exist, push them:
     ```bash
     git push -u origin <branch>
     ```

### Run Tests

5. **Run GUT tests before merge**
   ```bash
   # Load config for GODOT path
   if [ -f ".claude/config.local" ]; then source .claude/config.local; fi
   if [ -z "$GODOT" ]; then GODOT=$(command -v godot 2>/dev/null); fi
   $GODOT --headless -s addons/gut/gut_cmdln.gd
   ```
   - If tests fail, show errors and ask:
     "Tests failed. Options:"
     "1. Fix tests and try again"
     "2. Continue anyway (not recommended)"
     "3. Cancel"
   - Require explicit choice

### Execution

6. **Check if PR exists**
   ```bash
   gh pr list --head <branch> --state merged
   gh pr list --head <branch> --state open
   ```
   - If merged, skip to cleanup
   - If open, ask: "Merge PR now?"
   - If no PR, ask: "No PR found. Create one first with /pr?"

7. **Merge via PR**
   ```bash
   gh pr merge --squash --delete-branch
   ```

8. **Show cleanup instructions**
   ```
   PR merged!

   This clone can now be deleted. To clean up:

   1. Close this terminal
   2. Delete the clone folder:
      rm -rf "<clone path>"

   Or from the main repo, run /sync to see remaining clones.

   Main repo: <source path>
   ```

   Note: We don't auto-delete because Claude is running IN this directory.
   The user should close the terminal and delete manually, or we could
   delete from the main repo's session.

---

## Simple Branch Flow

If on a simple feature branch (not a clone or worktree):

### Safety Checks

1. **Get current branch**
   ```bash
   git branch --show-current
   ```
   - If on `main`, show error: "Already on main. Nothing to finish."
   - STOP

2. **Check for uncommitted changes**
   ```bash
   git status --porcelain
   ```
   - If changes exist, ask: "You have uncommitted changes. Commit first with /commit?"
   - STOP until resolved

3. **Check for unpushed commits**
   ```bash
   git log origin/<branch>..<branch> --oneline 2>/dev/null
   ```
   - If commits exist, push them:
     ```bash
     git push -u origin <branch>
     ```

### Run Tests

4. **Run GUT tests before merge**
   ```bash
   # Load config for GODOT path
   if [ -f ".claude/config.local" ]; then source .claude/config.local; fi
   if [ -z "$GODOT" ]; then GODOT=$(command -v godot 2>/dev/null); fi
   $GODOT --headless -s addons/gut/gut_cmdln.gd
   ```
   - If tests fail, show errors and ask:
     "Tests failed. Options:"
     "1. Fix tests and try again"
     "2. Continue anyway (not recommended)"
     "3. Cancel"
   - Require explicit choice

### Execution

5. **Check if PR exists**
   ```bash
   gh pr list --head <branch> --state open
   ```
   - If no PR, ask: "No PR found. Create one first with /pr?"
   - STOP if no PR

6. **Merge the PR**
   ```bash
   gh pr merge --squash --delete-branch
   ```

7. **Return to main**
   ```bash
   git checkout main
   git pull
   ```

8. **Clean up local branch (if still exists)**
   ```bash
   git branch -d <branch> 2>/dev/null || true
   ```

9. **Show success**
   ```
   Done! PR merged and branch cleaned up.

   You're back on main.
   ```
