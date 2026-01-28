---
allowed-tools: Bash
description: Delete clones with merged PRs
---

Clean up clones that have completed their work (PR merged).

Usage: /cleanup

## Steps

1. **Check we're in main repo (not a clone)**
   ```bash
   if [ -f ".clone-info" ]; then
     echo "Cannot run cleanup from inside a clone. Run from main repo."
     exit 1
   fi
   ```

2. **Find clones directory**
   ```bash
   REPO_ROOT=$(git rev-parse --show-toplevel)
   REPO_NAME=$(basename "$REPO_ROOT")
   CLONES_DIR=$(dirname "$REPO_ROOT")/.${REPO_NAME}-clones
   ```

3. **Check each clone for merged PRs**
   ```bash
   for clone in "$CLONES_DIR"/*; do
     if [ -d "$clone" ]; then
       NAME=$(basename "$clone")

       # Read clone info
       if [ -f "$clone/.clone-info" ]; then
         source "$clone/.clone-info"
         BRANCH="feature/$feature"
       else
         BRANCH=$(git -C "$clone" branch --show-current 2>/dev/null)
       fi

       # Check if PR is merged
       MERGED_PR=$(gh pr list --head "$BRANCH" --state merged --json number --jq '.[0].number' 2>/dev/null)

       if [ -n "$MERGED_PR" ]; then
         echo "✓ $NAME (PR #$MERGED_PR merged) - can delete"
         DELETABLE+=("$clone")
       else
         # Check if branch still has open PR
         OPEN_PR=$(gh pr list --head "$BRANCH" --state open --json number --jq '.[0].number' 2>/dev/null)
         if [ -n "$OPEN_PR" ]; then
           echo "⏳ $NAME (PR #$OPEN_PR open) - keep"
         else
           echo "? $NAME (no PR) - keep"
         fi
       fi
     fi
   done
   ```

4. **If deletable clones found, ask to delete**
   - Show list of clones that can be deleted
   - Ask: "Delete these clones?" (yes/no)
   - If yes, delete each one:
     ```bash
     for clone in "${DELETABLE[@]}"; do
       rm -r "$clone"
       echo "Deleted: $(basename $clone)"
     done
     ```

5. **Show result**
   ```
   Cleanup complete!

   Deleted: 2 clones
   Remaining: 1 clone
   ```

## Output Format

```
## Clone Cleanup

Scanning clones...

✓ 14-validate-port (PR #25 merged) - can delete
✓ 15-remove-debug-keys (PR #24 merged) - can delete
⏳ 21-synchronized-rng (PR #30 open) - keep

Delete 2 clones with merged PRs? (yes/no)
> yes

Deleted: 14-validate-port
Deleted: 15-remove-debug-keys

Cleanup complete!
```
