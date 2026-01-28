---
allowed-tools: Bash
description: Create a feature branch
argument-hint: <issue-number-or-name>
---

Create a feature branch in the current repository.

Use this for focused, sequential work in a single session.
For parallel work with multiple Claude sessions, use `/clone` instead.

Usage: /branch <issue-number-or-name>

## Safety Checks

1. **Validate argument provided**
   - If "$1" is empty, show:
     ```
     Usage: /branch <issue-number-or-name>

     Examples:
       /branch 42-health-regen
       /branch fix-ai-targeting

     This creates a feature branch in the current repo.
     For parallel work (separate Claude sessions), use /clone instead.
     ```
   - STOP if no argument

2. **Validate format**
   - Allowed: letters, numbers, hyphens, underscores
   - If invalid, show error and STOP

3. **Check for uncommitted changes**
   ```bash
   git status --porcelain
   ```
   - If changes exist, show them and ask:
     "You have uncommitted changes. Commit or stash them first?"
   - STOP until resolved

4. **Check we're on main**
   ```bash
   git branch --show-current
   ```
   - If not on main, warn:
     "You're on branch X. Switch to main first?"
   - If user confirms, run `git checkout main`

5. **Check if branch already exists**
   ```bash
   git branch --list "feature/$1"
   git branch -r --list "origin/feature/$1"
   ```
   - If exists locally: "Branch exists. Check it out?"
   - If exists on remote: "Branch exists on remote. Fetch and check out?"

6. **Pull latest main**
   ```bash
   git pull
   ```

## Execution

1. **Create and checkout branch**
   ```bash
   git checkout -b "feature/$1"
   ```

2. **If argument starts with a number, show linked issue**
   Extract issue number and run:
   ```bash
   gh issue view <number> --json title,body,labels --jq '"## Issue #\(.number // "?"): \(.title)\n\n**Labels:** \(.labels | map(.name) | join(", "))\n\n\(.body)"'
   ```

3. **Show success**
   ```
   Created feature/$1

   Ready to work. Commands:
   - /brief        Get full context on the linked issue
   - /commit       Commit your changes
   - /pr           Create pull request when done
   - /finish       Merge PR and return to main
   ```
