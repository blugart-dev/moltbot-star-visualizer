---
allowed-tools: Bash, Read, Grep, Glob
description: Review a pull request before merging
argument-hint: <pr-number>
---

Review a pull request's changes and provide a summary.

## Usage

```bash
/review 123       # Review PR #123
/review           # Review PR for current branch (if exists)
```

## Execution

1. **Get PR number**

   If argument provided, use it. Otherwise detect from current branch:
   ```bash
   BRANCH=$(git branch --show-current)
   PR_NUM=$(gh pr list --head "$BRANCH" --json number --jq '.[0].number' 2>/dev/null)
   ```

   If no PR found:
   ```
   No PR found for current branch. Usage: /review <pr-number>
   ```

2. **Fetch PR info**
   ```bash
   gh pr view $PR_NUM --json title,body,state,baseRefName,headRefName,files,additions,deletions,author
   ```

3. **Get the diff**
   ```bash
   gh pr diff $PR_NUM
   ```

4. **Review and summarize**

   Analyze the diff and provide:

   ### Summary
   - **PR**: #<number> - <title>
   - **Author**: <author>
   - **Branch**: <head> -> <base>
   - **Changes**: +<additions> / -<deletions> in <file_count> files

   ### Files Changed
   List each file with a one-line description of what changed.

   ### Analysis

   **What it does:**
   Brief description of the change's purpose.

   **Review checklist:**
   - [ ] Follows project patterns (no magic numbers/strings)
   - [ ] Static typing used
   - [ ] Entity/object validity checks correct
   - [ ] No debug print() statements (unless intentional)
   - [ ] Tests updated/added if behavior changed

   **Concerns (if any):**
   List any issues found, or "None" if clean.

   **Recommendation:**
   One of:
   - **Ready to merge** - No issues found
   - **Minor issues** - Can merge after addressing: <list>
   - **Needs work** - Should not merge: <reason>

5. **If ready to merge, offer merge command**
   ```
   To merge: gh pr merge $PR_NUM --squash --delete-branch
   ```
