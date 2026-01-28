---
allowed-tools: Bash
description: Create a pull request from current branch
---

Create a pull request for the current branch.

Usage: /pr [issue-number]

## Safety Checks

1. **Verify we're in a git repo**
   ```bash
   git rev-parse --git-dir
   ```

2. **Check we're not on main**
   ```bash
   git branch --show-current
   ```
   - If on `main`, show error: "Cannot create PR from main. Create a feature branch first."
   - Suggest: `/clone <issue-name>` or `/branch <feature-name>`

3. **Check for uncommitted changes**
   ```bash
   git status --porcelain
   ```
   - If changes exist, ask: "You have uncommitted changes. Commit first?"
   - If yes, run `/commit` flow

4. **Check if branch is pushed**
   ```bash
   git ls-remote --heads origin $(git branch --show-current)
   ```
   - If not pushed, push it:
     ```bash
     git push -u origin $(git branch --show-current)
     ```

5. **Check if PR already exists**
   ```bash
   gh pr list --head $(git branch --show-current)
   ```
   - If exists, show link and ask if they want to view it

## Execution

1. **Get branch info**
   ```bash
   BRANCH=$(git branch --show-current)
   COMMITS=$(git log main..$BRANCH --oneline)
   ```

2. **Determine linked issue**
   - If "$1" provided, use as issue number
   - Else, try to extract from branch name (e.g., `feature/42-health` -> 42)
   - Else, ask: "Link to an issue? (enter number or skip)"

3. **Generate PR title**
   - From branch name: `feature/42-health-regen` -> "Add health regen"
   - Or from first commit message
   - Ask user to confirm/edit

4. **Generate PR body**
   ```markdown
   ## Summary
   <generated from commits or ask user>

   ## Related Issue
   Closes #<issue-number>

   ## Changes
   <list from commits>

   ## Test Plan
   - [ ] Tested in Godot
   - [ ] No errors in Output panel
   ```

5. **Create PR**
   ```bash
   gh pr create \
     --title "<title>" \
     --body "<body>" \
     --base main
   ```

6. **Show result**
   ```
   Pull Request created!

   PR #45: Add health regeneration
   https://github.com/user/repo/pull/45

   Linked to: Issue #42

   Next steps:
   - Wait for CI (if configured)
   - Request review (if team)
   - Merge when ready: /finish
   ```
