# Moltbot Star Tracker

A visual celebration of [moltbot](https://github.com/moltbot/moltbot)'s GitHub star history, built with Godot 4.6.

Watch the growth of moltbot's stars over time, visualized as 3D lobsters swarming the screen.

## Features

- Visual timeline of GitHub stars from moltbot's first star to present
- 3D lobster models representing each star (matching moltbot's molting theme)
- Web playable + buildable from source
- Optimized for rendering tens of thousands of objects

## Try It

**Web**: [Coming soon]

**Build from source**: See [Building](#building) below

## Building

### Requirements

- [Godot 4.6](https://godotengine.org/download) or later
- Git

### Steps

```bash
git clone https://github.com/YOUR_USERNAME/moltbot-star-tracker.git
cd moltbot-star-tracker
```

Open the project in Godot and run.

## Development

This project uses Claude Code workflows. See [CLAUDE.md](CLAUDE.md) for development conventions.

### Quick Start

1. Copy `.claude/config.local.example` to `.claude/config.local`
2. Set your Godot path in `config.local`
3. Run `/sync` to get started

## License

[MIT](LICENSE)

## Credits

- [moltbot](https://github.com/moltbot/moltbot) - The AI assistant whose stars we're celebrating
- Built with [Godot Engine](https://godotengine.org)
