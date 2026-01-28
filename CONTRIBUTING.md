# Contributing

## Security Guidelines

Before committing, ensure you don't include:

| Never Commit | Why | Check |
|--------------|-----|-------|
| API keys/tokens | Exposed credentials | `grep -r "api_key\|token\|secret"` |
| `.env` files | Environment secrets | Already in `.gitignore` |
| `export_presets.cfg` | May contain signing keys | Already in `.gitignore` |
| `config.local` | Local machine paths | Already in `.gitignore` |
| Absolute paths | Exposes system info | `grep -r "/home/\|C:\\Users"` |

### Pre-commit Checklist

```bash
# Check for secrets patterns
git diff --cached | grep -iE "(api_key|token|password|secret|credential)"

# Check for absolute paths
git diff --cached | grep -E "(/home/|/Users/|C:\\\\)"

# List files being committed
git diff --cached --name-only
```

### What's Safe to Commit

- All `.gd`, `.tscn`, `.tres` files (Godot resources)
- Documentation (`.md` files)
- `.claude/commands/` (workflow templates, no secrets)
- `.claude/config.local.example` (template only)
- `data/star_history.json` (public star data)

## Development Setup

1. Clone the repo
2. Copy `.claude/config.local.example` to `.claude/config.local`
3. Set your local Godot path in `config.local`
4. Open project in Godot 4.6+

## Workflow

See [CLAUDE.md](CLAUDE.md) for full workflow documentation.

### Quick Reference

```bash
/sync           # Start of session
/branch <name>  # Create feature branch
/commit         # Commit with conventional prefix
/pr             # Create pull request
/finish         # Merge and cleanup
```

## Code Style

- **Static typing required** on all variables and functions
- **snake_case** for variables/functions, **PascalCase** for classes
- **`##` doc comments** for public APIs
- Keep lobster mesh under 500 triangles (web performance)

## Testing

```bash
/test           # Run all tests
/test unit      # Unit tests only
```
