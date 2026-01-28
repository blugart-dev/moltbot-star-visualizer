---
allowed-tools: Bash, Read
description: Show detailed status of all clones and background work
---

Show detailed status of all active clones, their progress, and any background Claude sessions.

## Data Gathering

Run these commands to gather clone status:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_ROOT")
CLONES_DIR=$(dirname "$REPO_ROOT")/.${REPO_NAME}-clones

echo "=== Clone Status ==="
echo ""

if [ ! -d "$CLONES_DIR" ] || [ -z "$(ls -A "$CLONES_DIR" 2>/dev/null)" ]; then
  echo "No active clones."
  echo ""
  echo "Create one with: /clone <issue-number>-<name>"
  exit 0
fi

for clone in "$CLONES_DIR"/*; do
  if [ -d "$clone" ]; then
    NAME=$(basename "$clone")
    echo "----------------------------------------"
    echo "$NAME"

    # Read clone info
    if [ -f "$clone/.clone-info" ]; then
      source "$clone/.clone-info"
      ISSUE_NUM=$(echo "$feature" | grep -oE '^[0-9]+')
      BRANCH="feature/$feature"
    else
      BRANCH=$(git -C "$clone" branch --show-current 2>/dev/null)
      ISSUE_NUM=$(echo "$BRANCH" | grep -oE '[0-9]+')
    fi

    # Branch info
    echo "   Branch: $BRANCH"
    [ -n "$ISSUE_NUM" ] && echo "   Issue:  #$ISSUE_NUM"

    # Git status
    UNCOMMITTED=$(git -C "$clone" status --porcelain 2>/dev/null | wc -l)
    COMMITS_AHEAD=$(git -C "$clone" rev-list --count origin/main..HEAD 2>/dev/null || echo "?")
    echo "   Commits ahead: $COMMITS_AHEAD"
    [ "$UNCOMMITTED" -gt 0 ] && echo "   Uncommitted files: $UNCOMMITTED"

    # Last commit
    LAST_COMMIT=$(git -C "$clone" log -1 --format="%h %s" 2>/dev/null)
    echo "   Last commit: $LAST_COMMIT"

    # PR status
    MERGED_PR=$(gh pr list --repo "$(git -C "$clone" remote get-url origin)" --head "$BRANCH" --state merged --json number --jq '.[0].number' 2>/dev/null)
    OPEN_PR=$(gh pr list --repo "$(git -C "$clone" remote get-url origin)" --head "$BRANCH" --state open --json number,url --jq '.[0] | "#\(.number) \(.url)"' 2>/dev/null)

    if [ -n "$MERGED_PR" ]; then
      echo "   PR: MERGED #$MERGED_PR - ready for cleanup"
    elif [ -n "$OPEN_PR" ]; then
      echo "   PR: OPEN $OPEN_PR"
    else
      echo "   PR: Not created yet"
    fi

    # Check for auto log (background Claude)
    if [ -f "$clone/claude-auto.log" ]; then
      LOG_SIZE=$(wc -l < "$clone/claude-auto.log")
      LOG_TAIL=$(tail -1 "$clone/claude-auto.log" 2>/dev/null)

      # Check if Claude is still running
      if pgrep -f "claude.*$clone" > /dev/null 2>&1; then
        echo "   Claude: RUNNING ($LOG_SIZE lines)"
      elif grep -q "FULL_AUTO_FAILED" "$clone/claude-auto.log" 2>/dev/null; then
        echo "   Claude: FAILED - check log"
      elif grep -q "FULL_AUTO_SUCCESS" "$clone/claude-auto.log" 2>/dev/null; then
        echo "   Claude: COMPLETED"
      else
        echo "   Claude: Log exists ($LOG_SIZE lines)"
      fi
      echo "   Log: $clone/claude-auto.log"
    fi

    echo ""
  fi
done

echo "----------------------------------------"
echo ""
echo "Commands:"
echo "  /cleanup     - Delete clones with merged PRs"
echo "  /sync        - Full project status"
echo "  tail -f <log> - Watch a background Claude"
```

## Output Format

Present the gathered information clearly:

```
=== Clone Status ===

----------------------------------------
21-synchronized-rng
   Branch: feature/21-synchronized-rng
   Issue:  #21
   Commits ahead: 3
   Last commit: a1b2c3d feat: Add RNG synchronization
   PR: OPEN #45 https://github.com/user/repo/pull/45
   Claude: COMPLETED
   Log: /path/to/clone/claude-auto.log

----------------------------------------
53-buildingmanager-types
   Branch: feature/53-buildingmanager-types
   Issue:  #53
   Commits ahead: 0
   Uncommitted files: 2
   Last commit: 4d5e6f7 Initial clone
   PR: Not created yet
   Claude: RUNNING (847 lines)
   Log: /path/to/clone/claude-auto.log

----------------------------------------

Commands:
  /cleanup      - Delete clones with merged PRs
  /sync         - Full project status
  tail -f <log> - Watch a background Claude
```

## Behavior

- Show all clones with their current state
- Highlight clones ready for cleanup (merged PRs)
- Show Claude background session status if log exists
- Provide actionable next steps
