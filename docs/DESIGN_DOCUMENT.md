# Design Document

## Vision

A visual celebration of moltbot's journey from first star to 78,000+, represented as a swarm of 3D lobsters growing over time.

## Goals

1. **Visual impact**: Impressive visualization that captures moltbot's explosive growth
2. **Accessible**: Runs in browser, no install required
3. **Open source**: MIT licensed, buildable from source, educational
4. **Clone and run**: No API keys, no setup friction, works offline

## Non-Goals

- Real-time GitHub integration (we use pre-cached data)
- Mobile app (web-first, desktop secondary)
- Multiplayer or social features
- Historical accuracy to the minute (daily granularity is fine)

## Core Experience

1. User opens the visualization (web or desktop)
2. Sees empty space, timeline at bottom showing moltbot's birth date
3. Presses play or scrubs timeline
4. Lobsters appear as stars accumulate - slow at first, then explosive growth
5. Can pause, rewind, speed up, slow down
6. Current star count and date always visible
7. Special visual flourishes at milestone moments

## Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Rendering | MultiMeshInstance3D | Idiomatic, documented, web-compatible |
| Data | Pre-cached JSON | No API keys, works offline, deterministic |
| License | MIT | Standard for this type of project |

See [ARCHITECTURE.md](ARCHITECTURE.md) for implementation details.

## Visual Design

### Lobster Models

- Low-poly 3D lobster (< 500 triangles)
- Matches moltbot branding colors
- Per-instance variation via shader (color tint, animation phase)
- Simple idle animation (gentle bob/sway)

### Scene Composition

- Dark background (space or deep ocean aesthetic)
- Lobsters swarm in 3D space around a central point
- Camera can orbit and zoom
- Timeline bar at bottom
- Star counter in corner

### Milestones

Special visual effects at key moments:

| Stars | Effect |
|-------|--------|
| 1 | First lobster appears with fanfare |
| 1,000 | Color pulse, brief pause |
| 10,000 | Camera zoom out, wave effect |
| 50,000 | Major celebration effect |
| Current | Confetti or similar |

## Milestones

### M1: Foundation
- [x] Project setup (Godot 4.6, GL Compatibility)
- [x] Documentation structure
- [x] Git workflow configured
- [x] Basic scene with camera controls
- [x] Placeholder cube as "lobster"

### M2: Rendering Pipeline
- [x] MultiMeshInstance3D setup
- [x] 10,000 instances rendering at 60 FPS
- [x] Per-instance shader variation working
- [x] Basic positioning algorithm (sphere packing or similar)

### M3: Data Integration
- [x] Python fetch script for star history
- [x] star_history.json with real data
- [x] DataProvider loading and parsing
- [x] Timeline scrubbing updates instance count

### M4: Timeline & Playback
- [x] Play/pause controls
- [x] Speed controls (0.5x, 1x, 2x, 5x, 10x)
- [x] Timeline bar with scrubbing
- [x] Date and count display

### M5: Polish
- [x] Real lobster model (procedural ~340 triangles)
- [x] Milestone effects (pause, camera zoom, particles - UX needs refinement)
- [~] Sound effects (AudioManager ready, audio files pending)
- [x] UI polish (dark theme, lobster-red accents)

### M6: Release
- [ ] Web export working
- [ ] GitHub Pages deployment
- [ ] README with screenshots/GIF
- [ ] Announce

## Open Questions

- [x] Exact lobster visual style (realistic vs stylized?) → Procedural low-poly (~340 triangles)
- [x] Sound? Music? Or silent? → Full audio (ambient loop + milestone sounds)
- [ ] Any interactivity beyond timeline? (click lobster for star info?)
- [ ] GitHub Pages or itch.io for hosting?

## Resources

- [moltbot/moltbot](https://github.com/moltbot/moltbot) - The project we're celebrating
- [star-history.com](https://star-history.com) - Reference for star history visualization
- [Godot MultiMesh docs](https://docs.godotengine.org/en/stable/classes/class_multimesh.html)
