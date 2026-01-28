---
allowed-tools: Bash
description: Create a new GitHub issue
---

Create a new GitHub issue for tracking work.

Usage: /issue [title]

## Steps

1. **Check gh authentication**
   ```bash
   gh auth status
   ```
   - If not authenticated, tell user to run `gh auth login`

2. **Get issue details**
   - If "$1" provided, use as title
   - If not, ask user for title

3. **Ask for issue type**
   Present options:
   - `feature` - New functionality
   - `bug` - Something broken
   - `enhancement` - Improve existing feature
   - `tech-debt` - Refactoring, cleanup
   - `documentation` - Docs updates

4. **Ask for priority**
   Present options:
   - `priority:critical` - Drop everything
   - `priority:high` - Do soon
   - `priority:medium` - Normal priority
   - `priority:low` - Backlog

5. **Ask for area** (optional)
   Present options based on project areas, e.g.:
   - `area:ai` - AI system
   - `area:combat` - Combat system
   - `area:economy` - Resources, gathering
   - `area:ui` - User interface
   - `area:core` - Core systems
   - Skip

6. **Ask for description**
   Ask user to describe the issue in a few sentences.

7. **Create the issue**
   ```bash
   gh issue create \
     --title "<title>" \
     --body "<description>" \
     --label "<type>" \
     --label "<priority>" \
     --label "<area>"  # if provided
   ```

8. **Show result**
   Display the issue URL and number.

9. **Ask about next steps**
   "Want to start working on this now?"
   - If yes, suggest:
     - `/clone <issue-number>-<short-name>` (opens new terminal with Claude ready)
     - `/branch <issue-number>-<short-name>` (same terminal)
