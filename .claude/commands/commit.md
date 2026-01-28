---
allowed-tools: Bash, Read
description: Smart commit with conventional prefix
argument-hint: [optional message hint]
---

Create a commit following project conventions:

1. Run `git status` to see changes
2. Run `git diff --staged` and `git diff` to understand what changed
3. Run `git log --oneline -3` to match commit style
4. Analyze the changes and determine the appropriate prefix:
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `refactor:` - Code restructuring
   - `docs:` - Documentation
   - `test:` - Tests
   - `chore:` - Maintenance
5. Draft a concise commit message (1-2 sentences) focusing on "why"
6. Stage relevant files with `git add`
7. Create the commit with Co-Authored-By trailer
8. If user provided hint "$1", incorporate it into the message

Do NOT push automatically - just create the commit.
