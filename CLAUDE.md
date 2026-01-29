# Moltbot Star Tracker - Claude Code Instructions

## Project Overview

**Engine**: Godot 4.6 | **Language**: GDScript | **Architecture**: MultiMesh + Pre-cached Data

A visual celebration of moltbot's GitHub star history. Displays the growth of stars over time using 3D lobster models, matching moltbot's molting/lobster theme. Targets both web export and buildable from source.

**Current Phase**: Initial Setup

## Project Structure

```
res://
├── data/             # Star history JSON (has .gdignore)
├── scenes/           # Scene files (.tscn)
├── scripts/          # GDScript files (.gd)
│   ├── core/         # LobsterManager, TimelineController, DataProvider
│   ├── ui/           # UI logic
│   └── tools/        # fetch_star_history.py
├── assets/           # Art, models, audio
│   ├── models/       # 3D lobster mesh
│   ├── materials/    # Lobster material
│   └── shaders/      # Instanced lobster shader
├── resources/        # Custom resources (.tres)
├── addons/           # Third-party addons (GUT)
└── tests/            # GUT test files
```

## Collaboration Model

**Claude writes**: Code (.gd), scenes (.tscn), resources (.tres), documentation
**Human does**: Godot Editor tasks (reload after `class_name`), testing, asset creation

### Important Notes

- **`.uid` Files**: Godot 4.x generates these for `class_name` scripts. Must be committed. Never gitignore.
- **Session Notes**: Use `.claude/NOTES.md` (gitignored) to persist learnings across sessions

---

## Critical Conventions

### Static Typing Required

```gdscript
var lobsters: Array[Lobster3D] = []
func get_star_count(date: String) -> int:
```

### Naming

- Variables/functions: `snake_case` | Classes: `PascalCase` | Constants: `SCREAMING_SNAKE_CASE` | Private: `_prefixed`
- Avoid shadowing: Use `display_name` not `name`, `target_position` not `position`

### Documentation (`##`)

Use `##` doc comments for class descriptions, signals, exports, and public functions. Use `#` for inline notes. Skip private helpers with obvious names.

---

## Architecture Quick Reference

- **Rendering**: MultiMeshInstance3D with per-instance shader variation
- **Data**: Pre-cached JSON (`data/star_history.json`), no runtime API calls
- **Scene root**: Main → World (LobsterManager, Camera) + TimelineController + DataProvider + UI

### Key Classes

| Class | Responsibility |
|-------|----------------|
| `LobsterManager` | MultiMesh setup, instance transforms, shader data |
| `TimelineController` | Playback state, date tracking, signals |
| `DataProvider` | Load JSON, provide star counts by date |

---

## Common Gotchas

- **Web export**: GL Compatibility renderer, test frequently in browser
- **MultiMesh instance_count**: Set before setting transforms, changing count clears data
- **JSON in data/**: Has `.gdignore`, load via `FileAccess`, not `load()`
- **Lobster mesh**: Keep under 500 triangles for web performance

---

## Common Tasks

### Fetching Star Data

Uses GitHub GraphQL API (bypasses REST API's 40k star limit). Requires a token:

```bash
cd scripts/tools
GITHUB_TOKEN=$(gh auth token) python fetch_star_history.py
# Output: data/star_history.json
```

### Testing Web Export

1. Export to web: Project → Export → Web
2. Run local server: `python -m http.server 8000` in export folder
3. Open `http://localhost:8000` in browser
4. Check console for errors, verify 30+ FPS

### Adding Lobster Instances

```gdscript
# In LobsterManager
multi_mesh.instance_count = new_count  # Must set count first
for i in range(new_count):
    multi_mesh.set_instance_transform(i, transform)
    multi_mesh.set_instance_custom_data(i, Color(r, g, b, phase))
```

---

## Testing

### Configuration

Set Godot path in `.claude/config.local` (copy from `.claude/config.local.example`):

```bash
GODOT=/path/to/godot
```

### Running Tests

```bash
/test                    # Preferred - auto-finds Godot
/test unit               # Unit tests only
/test integration        # Integration tests only
```

---

## Git Workflow

### Commands

| Command | Purpose |
|---------|---------|
| `/sync` | Pull (rebase), show status, clones, issues, PRs |
| `/status` | Detailed clone status with background Claude progress |
| `/branch <name>` | Create feature branch (sequential work, same terminal) |
| `/clone <name> [--auto\|--full-auto\|--quiet]` | Create isolated clone (parallel work, new terminal) |
| `/commit` | Smart commit with conventional prefix |
| `/pr` | Push + create pull request |
| `/finish` | Run tests, merge PR, cleanup |
| `/brief` | Show linked issue context |
| `/plan <issue>` | Research issue, add implementation notes |
| `/test` | Run GUT tests |
| `/issue` | Create new GitHub issue |
| `/cleanup` | Delete clones with merged PRs |
| `/audit` | Systematic codebase review |
| `/review <pr>` | Review PR diff before merge |
| `/catchup` | Read all changed files to restore context |

**Commit prefixes**: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`

### Parallel Development with /clone

Use `/clone` for parallel Claude sessions:

| Mode | Command | Live Output | Use Case |
|------|---------|-------------|----------|
| **Wait** | `/clone 21-feature` | Yes | Claude waits for instructions |
| **Auto** | `/clone 21-feature --auto` | Yes | Claude works, you can watch |
| **Full-Auto** | `/clone 21-feature --full-auto` | No | Auto-merges on success |
| **Quiet** | `/clone 21-feature --quiet` | No | Background, check logs |

```bash
/clone 21-synchronized-rng --auto    # Recommended: live output, can intervene
/finish                              # When done: tests -> PR -> merge
/cleanup                             # From main: delete merged clones
```

**Good candidates for autonomous modes:**
- `claude-friendly` + `effort:small` labels
- Single file or non-overlapping changes
- Clear acceptance criteria

Clones live in `../.moltbot-star-tracker-clones/`.

### Sequential Development

```bash
/branch 14-validate-port      # Creates branch, same terminal
/brief                        # Get issue context
# ... work ...
/finish                       # Tests -> PR -> merge -> back to main
```

---

## Periodic Maintenance

### Codebase Health Audit

```bash
/audit                         # Start or continue audit
/audit scripts/core/           # Audit specific directory
/audit --execute               # Convert findings to issues
/audit --run                   # Launch Claude sessions for fixes
```

### Issue Triage

```bash
# High priority, small effort, claude-friendly
gh issue list --label "priority:high" --label "effort:small" --label "claude-friendly"

# By type
gh issue list --label "tech-debt"
gh issue list --label "area:rendering"
```

### Label System

| Category | Labels |
|----------|--------|
| **Priority** | `priority:critical`, `priority:high`, `priority:medium`, `priority:low` |
| **Effort** | `effort:small`, `effort:medium`, `effort:large` |
| **Area** | `area:core`, `area:rendering`, `area:data`, `area:ui`, `area:web`, `area:test` |
| **Type** | `bug`, `enhancement`, `tech-debt`, `documentation` |
| **Workflow** | `claude-friendly`, `good first issue` |
