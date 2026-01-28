---
allowed-tools: Bash, Read
description: Sync repo and show project status
---

Sync the repository and show current project status.

## Data Gathering

1. Pull latest changes (use rebase to avoid merge commits):
   ```bash
   git pull --rebase
   ```

2. Check for uncommitted work: `git status --porcelain`
3. Get current branch: `git branch --show-current`
4. Show recent commits: `git log --oneline -5`
5. List active clones and their details:
   ```bash
   REPO_ROOT=$(git rev-parse --show-toplevel)
   REPO_NAME=$(basename "$REPO_ROOT")
   CLONES_DIR=$(dirname "$REPO_ROOT")/.${REPO_NAME}-clones

   for clone in "$CLONES_DIR"/*; do
     if [ -d "$clone" ]; then
       NAME=$(basename "$clone")

       # Read clone info for issue number
       if [ -f "$clone/.clone-info" ]; then
         source "$clone/.clone-info"
         ISSUE_NUM=$(echo "$feature" | grep -oE '^[0-9]+')
         BRANCH="feature/$feature"
       else
         BRANCH=$(git -C "$clone" branch --show-current 2>/dev/null)
         ISSUE_NUM=$(echo "$BRANCH" | grep -oE '[0-9]+')
       fi

       # Check PR status
       MERGED_PR=$(gh pr list --head "$BRANCH" --state merged --json number --jq '.[0].number' 2>/dev/null)
       OPEN_PR=$(gh pr list --head "$BRANCH" --state open --json number --jq '.[0].number' 2>/dev/null)

       # Format output
       if [ -n "$MERGED_PR" ]; then
         STATUS="✓ PR #$MERGED_PR merged - run /cleanup"
       elif [ -n "$OPEN_PR" ]; then
         STATUS="PR #$OPEN_PR open"
       else
         STATUS="no PR"
       fi

       # Show issue link if we have issue number
       if [ -n "$ISSUE_NUM" ]; then
         echo "$NAME/ [$BRANCH] → Issue #$ISSUE_NUM ($STATUS)"
       else
         echo "$NAME/ [$BRANCH] ($STATUS)"
       fi
     fi
   done
   ```

6. Show open GitHub issues: `gh issue list --limit 10`
7. Show open PRs: `gh pr list`

## Output Format

```
## Project Status

**Branch:** main (clean)

**Uncommitted Changes:**
  M .claude/settings.json
  A scripts/new_file.gd

> You have uncommitted changes. What would you like to do?
> - `/commit` to commit them
> - `git stash` to stash them
> - `git checkout -- <file>` to discard them

**Active Clones:**
  14-validate-port/       [feature/14-validate-port] → Issue #14 (✓ PR #25 merged - run /cleanup)
  21-synchronized-rng/    [feature/21-synchronized-rng] → Issue #21 (PR #30 open)
  new-feature/            [feature/new-feature] (no PR)

**Open Issues (3):**
- #4 [enhancement] Add death animation
- #1 [bug] AI duplicate barracks
- #7 [feature] Add multiplayer support

**Open PRs (1):**
- #45 feat: Implement LAN discovery (feature/multiplayer)

**Recent Work:**
- e75d7d3 feat: Implement attack-move command
- 2ab923d docs: Update MVP milestones

**Suggested Next:**
Pick an issue to work on:
- `/clone 4-death-animation` for parallel work (opens new terminal with Claude)
- `/branch 4-death-animation` for sequential work (same terminal)
- `/cleanup` to delete clones with merged PRs
- `/issue` to create a new issue
```

Note: Only show the "Uncommitted Changes" section if there are uncommitted changes. If the branch is clean, show `(clean)` next to the branch name and omit this section.

## Behavior

- If uncommitted changes exist, ask the user what to do
- If on a feature branch, mention `/finish` to complete it
- If in a clone, show path to main repo
- Suggest `/clone` for parallel work (emphasize it opens a new terminal with Claude ready)
- If any clones have merged PRs, suggest `/cleanup` to delete them
