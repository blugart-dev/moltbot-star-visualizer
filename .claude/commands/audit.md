---
allowed-tools: Bash, Read, Glob, Grep, Task, Edit, Write
description: Systematic codebase review with issue creation
argument-hint: [directory|--continue|--execute]
---

Perform a systematic codebase audit to identify technical debt, code quality issues, and improvement opportunities.

## Modes

- `/audit` or `/audit <directory>` - Start/continue audit, reviewing code
- `/audit --continue` - Resume audit from where you left off (reads NOTES.md)
- `/audit --execute` - Create GitHub issues from completed audit findings
- `/audit --run` - Launch parallel Claude sessions for existing audit issues

## Workflow Overview

1. **Audit Phase** - Review code directory by directory, document findings
2. **Issue Phase** - Convert findings into GitHub issues with proper labels
3. **Execute Phase** - Launch parallel Claude sessions to fix issues
4. **Review Phase** - Review PRs, merge, cleanup

## Audit Phase (`/audit` or `/audit <directory>`)

### 1. Check for existing audit state

```bash
if [ -f ".claude/NOTES.md" ]; then
  # Check for "## Codebase Audit" section
  grep -q "## Codebase Audit" .claude/NOTES.md
fi
```

- If audit section exists, show progress and ask: "Continue from where you left off?"
- If no audit section, initialize one

### 2. Initialize audit section in NOTES.md (if needed)

Add this structure to `.claude/NOTES.md`:

```markdown
---

## Codebase Audit

Systematic review of implementation quality, architecture, and improvement opportunities.

### Audit Progress

| Directory | Files | Status |
|-----------|-------|--------|
| autoload/ | ? | pending |
| scripts/ | ? | pending |
| tests/ | ? | skipped (test files) |

### Findings

#### High Priority (Architecture/Design Issues)
(findings will be added here)

#### Medium Priority (Implementation Improvements)
(findings will be added here)

#### Low Priority (Code Quality/Polish)
(findings will be added here)

---
```

### 3. Review directories systematically

For each directory marked "pending":

a. **List files:**
   ```bash
   ls -la <directory>/*.gd 2>/dev/null | wc -l
   ```

b. **Read each file** and evaluate against criteria:

   **High Priority (Architecture/Design):**
   - Code smell patterns (god classes, feature envy)
   - Test code mixed with production code
   - Backwards compatibility hacks
   - Undefined/incorrect constant references
   - Security issues

   **Medium Priority (Implementation):**
   - Inconsistent patterns within file or vs codebase
   - Missing validation or error handling
   - Debug code left in production paths
   - Duplicate code that could be consolidated
   - Private member access from outside class

   **Low Priority (Polish):**
   - Large files that could be decomposed
   - Missing documentation for complex logic
   - Minor code duplication
   - Naming inconsistencies
   - Dead code

c. **Document findings** with:
   - File path and line number(s)
   - What the issue is
   - Why it matters
   - Suggested fix approach

d. **Update progress table** - Mark directory as "complete"

e. **Create detailed review section** for the directory (optional, for complex directories)

### 4. After completing a directory

Update NOTES.md with:
- Progress table status
- Any new findings added to appropriate priority section
- Detailed file-by-file notes (for reference)

## Issue Phase (`/audit --execute`)

### 1. Parse findings from NOTES.md

Read the Findings section and extract:
- Priority level
- Description
- File locations
- Suggested approach

### 2. Check existing issues

```bash
gh issue list --label "tech-debt" --state all --json number,title
```

Avoid creating duplicates.

### 3. Create GitHub issues

For each finding not already tracked:

```bash
gh issue create \
  --title "refactor: <brief description>" \
  --body "$(cat <<'EOF'
## Problem

<description of the issue>

## Location

- `path/to/file.gd:line` - <what's wrong here>

## Suggested Fix

<approach>

## Acceptance Criteria

- [ ] <specific outcome>
- [ ] Tests pass
EOF
)" \
  --label "tech-debt" \
  --label "<priority-label>" \
  --label "<area-label>" \
  --label "claude-friendly"  # if suitable for autonomous work
```

**Labels to use:**
- Priority: `priority:high`, `priority:medium`, `priority:low`
- Effort: `effort:small` (single file), `effort:medium` (2-3 files), `effort:large` (architectural)
- Area: Based on your project areas
- Type: `tech-debt`, `enhancement`, `bug`
- Workflow: `claude-friendly` (if isolated, clear criteria, existing tests)

### 4. Update NOTES.md

Mark findings as "Issue #XX created" to track what's been filed.

## Execute Phase (`/audit --run`)

### 1. List audit issues

```bash
gh issue list --label "tech-debt" --state open --json number,title,labels
```

### 2. Prioritize and select

- Start with `priority:high` + `effort:small` + `claude-friendly`
- Group related issues to avoid conflicts
- Suggest batch size (3-5 for parallel execution)

### 3. Launch parallel Claude sessions

For each selected issue:

```bash
# Extract issue number and short name
ISSUE_NUM=<number>
ISSUE_NAME=$(gh issue view $ISSUE_NUM --json title -q '.title' | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-30)

# Use /clone to launch
/clone $ISSUE_NUM-$ISSUE_NAME --auto
```

### 4. Track progress

Show:
```
Launched parallel sessions for:
- #XX: <title> (clone: XX-name)
- #YY: <title> (clone: YY-name)

Monitor with:
  gh pr list
  /status

When complete:
  Review PRs, merge, then /cleanup
```

## Review Phase

After parallel sessions complete:

1. **List PRs:** `gh pr list`
2. **Review each:** `gh pr diff <number>`
3. **Merge:** `gh pr merge <number> --squash --delete-branch`
4. **Cleanup:** `/cleanup`
5. **Update NOTES.md:** Mark findings as "Fixed PR #XX"

## Quality Guidelines

### What makes a good audit finding

- **Specific** - Points to exact file and line numbers
- **Actionable** - Clear what needs to change
- **Justified** - Explains why it matters (performance, maintainability, bugs)
- **Scoped** - One issue per finding, not "fix everything in this file"

### What to skip

- Style preferences without impact
- Hypothetical improvements ("could be faster")
- Changes that require product decisions
- Test file implementation details

### Prioritization criteria

**High Priority:**
- Could cause bugs or crashes
- Blocks other improvements
- Security implications
- Significant code smell affecting multiple files

**Medium Priority:**
- Inconsistent with codebase patterns
- Performance impact
- Maintainability concern
- Missing error handling

**Low Priority:**
- Code organization/readability
- Minor duplication
- Documentation gaps
- Nice-to-have polish
