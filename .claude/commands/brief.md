---
allowed-tools: Bash, Read
description: Get briefed on the current branch's issue
---

Auto-detect the issue from the branch name and present the task.

This is automatically run when you use `/clone` - Claude will be briefed and ready to work.

## Steps

1. **Get current branch:**
   ```bash
   git branch --show-current
   ```

2. **Extract issue number from branch name:**
   - Branch: `feature/4-death-animation` -> Issue #4
   - Branch: `feature/21-synchronized-rng` -> Issue #21
   - Pattern: Look for number after `feature/` or `fix/` or `bugfix/`

3. **If on main or no issue number found:**
   ```
   You're on the main branch.

   To work on an issue:
   - /clone <issue>-<name>  (parallel work, new terminal)
   - /branch <issue>-<name> (sequential work, same terminal)

   Or check open issues: gh issue list
   ```
   STOP here.

4. **Check if in a clone and get source repo path:**
   ```bash
   if [ -f ".clone-info" ]; then
     cat .clone-info
     SOURCE_REPO=$(grep '^source=' .clone-info | cut -d= -f2)
   fi
   ```

5. **Fetch issue details from GitHub:**
   If in a clone (SOURCE_REPO is set), run gh from the source repo since clones have local remotes:
   ```bash
   # If in a clone, use the source repo for gh commands
   if [ -n "$SOURCE_REPO" ]; then
     gh issue view <number> --json title,body,labels,state --repo "$(cd "$SOURCE_REPO" && gh repo view --json nameWithOwner -q .nameWithOwner)"
   else
     gh issue view <number> --json title,body,labels,state
   fi
   ```
   Note: Always use `--json` to avoid deprecated GitHub Projects (classic) API errors.

6. **Read CLAUDE.md for project context**

7. **Present the task:**
   ```
   ## Issue #<number>: <title>

   **Labels:** <labels>

   **Description:**
   <issue body>

   **Acceptance Criteria:**
   <extracted from issue>

   ---

   Ready to start. What would you like me to do first?
   - Explore the relevant code
   - Implement the fix/feature
   - Ask clarifying questions
   ```

This command is designed to be the FIRST thing run in a new clone.
With `/clone`, it runs automatically so Claude is immediately briefed.
