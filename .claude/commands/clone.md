---
allowed-tools: Bash
description: Create an isolated clone for parallel development
argument-hint: <issue-number-or-name> [--auto | --full-auto]
---

Create an isolated git clone and auto-launch Claude to work on it.

Each clone has its own `.git/` directory = zero conflicts between Claude sessions.

Usage:
- `/clone <issue-number-or-name>` - Create clone, Claude waits for instructions (live output)
- `/clone <issue-number-or-name> --auto` - Create clone, Claude starts working immediately (live output, recommended for monitoring)
- `/clone <issue-number-or-name> --full-auto` - Fully autonomous: implement -> test -> PR -> merge (no live output - logs appear when done)
- `/clone <issue-number-or-name> --quiet` - Like --full-auto but no terminal (background, check logs when done)

**Live Output Note:** Only the first two modes (no flag and `--auto`) show real-time progress. The `--full-auto` and `--quiet` modes buffer output because Claude's `-p` flag doesn't stream to non-TTY destinations. Use `--auto` if you want to watch Claude work.

## Safety Checks

1. **Validate feature name provided**
   - If "$1" is empty, show:
     ```
     Usage: /clone <issue-number-or-name> [--auto]

     Examples:
       /clone 21-synchronized-rng        # Claude waits for instructions
       /clone 14-validate-port --auto    # Claude starts working immediately

     This creates an isolated clone and opens a new terminal with Claude.
     For sequential work in the same repo, use /branch instead.
     ```
   - STOP if no argument

2. **Parse arguments**
   - Check if `--auto`, `--full-auto`, or `--quiet` flag is present
   - Extract feature name (first non-flag argument)

3. **Validate feature name format**
   ```bash
   echo "$FEATURE" | grep -E '^[a-zA-Z0-9_-]+$'
   ```
   - If invalid, show error and STOP
   - Allowed: letters, numbers, hyphens, underscores

4. **Check for uncommitted changes**
   ```bash
   git status --porcelain
   ```
   - If changes exist, WARN:
     "You have uncommitted changes. They will stay here, not in the clone."
   - Ask: "Continue anyway?" - require explicit yes

5. **Push any unpushed commits first (prevents divergent branches)**
   ```bash
   git log origin/$(git branch --show-current)..HEAD --oneline
   ```
   - If unpushed commits exist, push them:
     ```bash
     git push
     ```
   - This ensures clones start from the latest pushed state

6. **Check if clone already exists**
   ```bash
   REPO_ROOT=$(git rev-parse --show-toplevel)
   REPO_NAME=$(basename "$REPO_ROOT")
   CLONES_DIR=$(dirname "$REPO_ROOT")/.${REPO_NAME}-clones
   TARGET="$CLONES_DIR/$FEATURE"

   test -d "$TARGET"
   ```
   - If exists, show:
     "Clone '$FEATURE' already exists at $TARGET"
   - Ask: "Open it anyway?" and if yes:
     - First update the clone with latest from main:
       ```bash
       git -C "$TARGET" pull origin main --rebase
       ```
     - Update .claude/ config to get latest workflow commands:
       ```bash
       cp -r "$REPO_ROOT/.claude" "$TARGET/"
       ```
     - Then skip to step 8 (Launch Terminal)

7. **Check if branch already exists**
   ```bash
   git branch --list "feature/$FEATURE"
   git branch -r --list "origin/feature/$FEATURE"
   ```
   - If exists locally or on remote: "Branch exists. Use it in the clone?"

## Execution

1. **Determine paths:**
   ```bash
   REPO_ROOT=$(git rev-parse --show-toplevel)
   REPO_NAME=$(basename "$REPO_ROOT")
   CLONES_DIR=$(dirname "$REPO_ROOT")/.${REPO_NAME}-clones
   TARGET="$CLONES_DIR/$FEATURE"
   REMOTE_URL=$(git remote get-url origin)
   ```

2. **Create clones directory:**
   ```bash
   mkdir -p "$CLONES_DIR"
   ```

3. **Clone the repository:**
   ```bash
   git clone "$REMOTE_URL" "$TARGET" --branch main
   ```

4. **Create feature branch:**
   ```bash
   git -C "$TARGET" checkout -b "feature/$FEATURE"
   ```
   Or if using existing remote branch:
   ```bash
   git -C "$TARGET" fetch origin "feature/$FEATURE"
   git -C "$TARGET" checkout "feature/$FEATURE"
   ```

5. **Extract issue number from feature name:**
   ```bash
   ISSUE_NUM=$(echo "$FEATURE" | grep -oE '^[0-9]+')
   ```

6. **Create clone marker file:**
   ```bash
   cat > "$TARGET/.clone-info" <<EOF
source=$REPO_ROOT
created=$(date -Iseconds)
feature=$FEATURE
issue=$ISSUE_NUM
EOF
   ```
   Note: No indentation inside heredoc - values must start at column 0 for parsing.

7. **Copy .claude/ config:**
   ```bash
   cp -r "$REPO_ROOT/.claude" "$TARGET/"
   ```

8. **Launch Claude (Mode-Dependent)**

   ### Mode A: `--full-auto` (Autonomous with Compact Log Viewer)

   Runs Claude in background, opens a small terminal tailing the log. Auto-closes on success, stays open on failure.

   **Note:** Output is buffered - the log viewer won't show progress until Claude finishes. This is due to Claude's `-p` flag not streaming to non-TTY. Use `--auto` if you need live progress.

   **Linux (gnome-terminal):**
   ```bash
   LOG="$TARGET/claude-auto.log"

   # Start the background worker
   nohup bash -c "
     cd '$TARGET'
     echo '==' > '$LOG'
     echo '  Full-Auto: $FEATURE' >> '$LOG'
     echo '  Started: '\$(date '+%H:%M:%S') >> '$LOG'
     echo '==' >> '$LOG'
     echo '' >> '$LOG'

     claude --dangerously-skip-permissions -p '/brief then /plan to research and add implementation notes (skip if notes already exist), then implement the fix/feature. Run /test to verify. If tests pass, run /pr to create a pull request.' >> '$LOG' 2>&1
     CLAUDE_EXIT=\$?

     echo '' >> '$LOG'
     echo '==' >> '$LOG'

     if [ \$CLAUDE_EXIT -ne 0 ]; then
       echo '  FAILED: Claude exited with error' >> '$LOG'
       echo 'FULL_AUTO_FAILED' >> '$LOG'
       if command -v notify-send &>/dev/null; then
         notify-send -u critical -i dialog-error 'Clone Failed' '$FEATURE: Claude exited with error'
       fi
       exit 1
     fi

     BRANCH='feature/$FEATURE'
     PR_NUM=\$(gh pr list --head \"\$BRANCH\" --json number --jq '.[0].number' 2>/dev/null)

     if [ -z \"\$PR_NUM\" ]; then
       echo '  FAILED: No PR created' >> '$LOG'
       echo 'FULL_AUTO_FAILED' >> '$LOG'
       if command -v notify-send &>/dev/null; then
         notify-send -u critical -i dialog-error 'Clone Failed' '$FEATURE: No PR created'
       fi
       exit 1
     fi

     echo \"  PR #\$PR_NUM created. Running final tests...\" >> '$LOG'
     echo '' >> '$LOG'

     # Load config for GODOT path
     if [ -f '.claude/config.local' ]; then source .claude/config.local; fi
     if [ -z \"\$GODOT\" ]; then GODOT=\$(command -v godot 2>/dev/null); fi
     if [ -n \"\$GODOT\" ]; then
       \$GODOT --headless -s addons/gut/gut_cmdln.gd >> '$LOG' 2>&1
     else
       echo '  Warning: Godot not found, skipping tests' >> '$LOG'
     fi
     TEST_EXIT=\$?

     echo '' >> '$LOG'
     echo '==' >> '$LOG'

     if [ \$TEST_EXIT -ne 0 ]; then
       echo \"  NEEDS REVIEW: Tests failed. PR #\$PR_NUM not merged.\" >> '$LOG'
       echo 'FULL_AUTO_NEEDS_REVIEW' >> '$LOG'
       if command -v notify-send &>/dev/null; then
         notify-send -u normal -i dialog-warning 'Clone Needs Review' '$FEATURE: Tests failed, PR not merged'
       fi
       exit 1
     fi

     gh pr merge \$PR_NUM --squash --delete-branch >> '$LOG' 2>&1
     if [ \$? -eq 0 ]; then
       echo \"  SUCCESS: PR #\$PR_NUM merged!\" >> '$LOG'
       echo 'FULL_AUTO_SUCCESS' >> '$LOG'
       if command -v notify-send &>/dev/null; then
         notify-send -i dialog-ok 'Clone Complete' '$FEATURE: PR merged successfully'
       fi
     else
       echo \"  FAILED: Could not merge PR #\$PR_NUM\" >> '$LOG'
       echo 'FULL_AUTO_FAILED' >> '$LOG'
       if command -v notify-send &>/dev/null; then
         notify-send -u critical -i dialog-error 'Clone Failed' '$FEATURE: Could not merge PR'
       fi
       exit 1
     fi
   " > /dev/null 2>&1 &

   WORKER_PID=$!

   # Open compact terminal to tail the log
   gnome-terminal --title="$FEATURE" --geometry=100x15 --working-directory="$TARGET" -- bash -c '
     LOG="claude-auto.log"
     FEATURE="'"$FEATURE"'"

     # Wait for log file to exist
     while [ ! -f "$LOG" ]; do sleep 0.1; done

     # Tail until we see a final status
     tail -f "$LOG" &
     TAIL_PID=$!

     # Watch for completion
     while true; do
       if grep -q "FULL_AUTO_SUCCESS" "$LOG" 2>/dev/null; then
         kill $TAIL_PID 2>/dev/null
         echo ""
         echo "Closing in 3 seconds..."
         sleep 3
         exit 0
       elif grep -q "FULL_AUTO_FAILED\|FULL_AUTO_NEEDS_REVIEW" "$LOG" 2>/dev/null; then
         kill $TAIL_PID 2>/dev/null
         echo ""
         echo "Press Enter to close..."
         read
         exit 1
       fi
       sleep 1
     done
   '
   ```

   **Windows (Windows Terminal):**
   ```bash
   # Similar approach: background worker + compact tail window
   wt -d "$TARGET" --title "$FEATURE" --size 100,15 cmd /k "powershell -Command \"Get-Content claude-auto.log -Wait -Tail 50\""
   ```

   **macOS:**
   ```bash
   osascript -e "tell app \"Terminal\" to do script \"cd '$TARGET' && tail -f claude-auto.log\""
   ```

   ### Mode B: `--quiet` (Background, No Terminal)

   For batch operations or when you don't need visual feedback. Logs to file.

   **Note:** Same buffering behavior as `--full-auto` - logs appear when Claude finishes, not during execution.

   ```bash
   LOG="$TARGET/claude-auto.log"

   nohup bash -c "
     cd '$TARGET'
     echo '=== Started: '\$(date) > '$LOG'
     claude --dangerously-skip-permissions -p '/brief then /plan to research and add implementation notes (skip if notes already exist), then implement the fix/feature. Run /test to verify. If tests pass, run /pr to create a pull request.' >> '$LOG' 2>&1

     BRANCH='feature/$FEATURE'
     PR_NUM=\$(gh pr list --head \"\$BRANCH\" --json number --jq '.[0].number' 2>/dev/null)

     if [ -n \"\$PR_NUM\" ]; then
       echo '' >> '$LOG'
       echo '=== Final test before merge ===' >> '$LOG'
       # Load config for GODOT path
       if [ -f '.claude/config.local' ]; then source .claude/config.local; fi
       if [ -z \"\$GODOT\" ]; then GODOT=\$(command -v godot 2>/dev/null); fi
       if [ -n \"\$GODOT\" ]; then
         \$GODOT --headless -s addons/gut/gut_cmdln.gd >> '$LOG' 2>&1
       else
         echo 'Warning: Godot not found, skipping tests' >> '$LOG'
       fi

       if [ \$? -eq 0 ]; then
         gh pr merge \$PR_NUM --squash --delete-branch >> '$LOG' 2>&1
         echo 'FULL_AUTO_SUCCESS' >> '$LOG'
         if command -v notify-send &>/dev/null; then
           notify-send -i dialog-ok 'Clone Complete' '$FEATURE: PR merged successfully'
         fi
       else
         echo 'FULL_AUTO_NEEDS_REVIEW' >> '$LOG'
         if command -v notify-send &>/dev/null; then
           notify-send -u normal -i dialog-warning 'Clone Needs Review' '$FEATURE: Tests failed, PR not merged'
         fi
       fi
     else
       echo 'FULL_AUTO_FAILED' >> '$LOG'
       if command -v notify-send &>/dev/null; then
         notify-send -u critical -i dialog-error 'Clone Failed' '$FEATURE: No PR created'
       fi
     fi
     echo '=== Finished: '\$(date) >> '$LOG'
   " > /dev/null 2>&1 &

   echo "Quiet mode started in background"
   echo "Log: $LOG"
   echo "Monitor: tail -f $LOG"
   ```

   ### Mode C: `--auto` (Interactive Terminal) - RECOMMENDED FOR MONITORING

   Opens terminal with Claude working automatically, but you can watch/intervene. **This mode shows live output** because Claude runs in an interactive TTY.

   **Detect platform:**
   ```bash
   case "$(uname -s)" in
     Linux*)  PLATFORM="linux" ;;
     Darwin*) PLATFORM="mac" ;;
     MINGW*|MSYS*|CYGWIN*) PLATFORM="windows" ;;
     *)       PLATFORM="unknown" ;;
   esac
   ```

   **Linux (gnome-terminal):**
   ```bash
   gnome-terminal --working-directory="$TARGET" -- bash -c 'claude --dangerously-skip-permissions "/brief then /plan (if no implementation notes exist), then implement the fix/feature"; exec bash'
   ```

   **Windows (Windows Terminal or cmd):**
   ```bash
   if command -v wt &> /dev/null; then
     wt -d "$TARGET" cmd /k "claude --dangerously-skip-permissions \"/brief then /plan (if no implementation notes exist), then implement the fix/feature\""
   else
     start cmd /k "cd /d \"$TARGET\" && claude --dangerously-skip-permissions \"/brief then /plan (if no implementation notes exist), then implement the fix/feature\""
   fi
   ```

   **macOS:**
   ```bash
   osascript -e "tell app \"Terminal\" to do script \"cd '$TARGET' && claude --dangerously-skip-permissions '/brief then /plan (if no implementation notes exist), then implement the fix/feature'\""
   ```

   ### Mode D: No Flag (Interactive, Waiting)

   Opens terminal with Claude waiting for instructions. **Live output** - you see everything in real-time.

   **Linux:**
   ```bash
   gnome-terminal --working-directory="$TARGET" -- bash -c 'claude --dangerously-skip-permissions "/brief"; exec bash'
   ```

   (Similar for other platforms, just change the prompt to `"/brief"`)

9. **Show success:**

   **For `--full-auto`:**
   ```
   Full-auto clone launched!

   Path:   <full path>
   Branch: feature/<name>
   Issue:  #<number>
   Log:    <path>/claude-auto.log

   A compact terminal opened showing live progress.
   - On success: auto-merges PR, closes after 3s
   - On failure: stays open for investigation

   Active clones:
   <list from clones directory>
   ```

   **For `--quiet`:**
   ```
   Quiet mode started in background!

   Path:   <full path>
   Branch: feature/<name>
   Issue:  #<number>
   Log:    <path>/claude-auto.log

   Monitor with: tail -f <log-path>
   Check status: grep FULL_AUTO <log-path>
   ```

   **For `--auto` or no flag:**
   ```
   Clone created and Claude launched!

   Path:   <full path>
   Branch: feature/<name>
   Issue:  #<number> (if detected)
   Mode:   <auto-work | waiting for instructions>

   A new terminal opened with Claude running.

   When done in that session: /finish

   Active clones:
   <list from clones directory>
   ```
