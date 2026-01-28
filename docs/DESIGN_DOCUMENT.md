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

- [x] Low-poly 3D lobster (~340 triangles, procedural)
- [ ] Matches moltbot branding colors (lobster red-orange)
- [ ] Per-instance variation via shader (color tint, animation phase)
- [x] Simple idle animation (bob + sway via shader)

### Scene Composition

- [x] Deep ocean background (blue gradient sky with fog)
- [x] Glowing bioluminescent core at center
- [x] Lobsters swarm in 3D space (Fibonacci sphere distribution)
- [x] Camera orbits and auto-zooms with swarm
- [x] Timeline bar at bottom (dark theme)
- [x] Star counter (lobster-red accent)
- [x] Atmospheric lighting (fog, glow, HDR)

### Milestones

Subtle celebration effects at key star counts (no playback interruption):

| Stars | Effect |
|-------|--------|
| 1 | First lobster appears, small particle burst |
| 1,000 | Medium particle burst, milestone sound |
| 10,000 | Large particle burst, milestone sound |
| 50,000 | Epic particle burst, special sound |
| Final | Celebration particles, completion sound |

Camera auto-zooms continuously to keep swarm visible - no jarring zoom effects.

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

### M5: Core Polish (DONE)
- [x] Real lobster model (procedural ~340 triangles)
- [x] Milestone detection system
- [x] Auto-zoom camera (smooth, follows swarm growth)
- [x] Basic milestone particles
- [x] UI dark theme foundation

### M6: Visual Quality
- [x] Skybox (deep ocean theme with fog)
- [x] Lobster idle animation (bob + sway via shader)
- [x] Better lighting and atmosphere (fog, glow, blue tones)
- [x] Glowing bioluminescent core at center
- [x] Particle polish (cyan bioluminescent colors)
- [ ] Milestone visual feedback (count popup - optional)

### M7: UI & Audio
- [ ] Timeline bar refinement (tick marks, milestone indicators)
- [ ] Stats overlay (total stars, current date prominent)
- [ ] Loading/intro screen
- [ ] Sound effects (ambient + milestone chimes)
- [ ] Help/controls overlay (optional)

### M8: Release
- [ ] Web export testing (30+ FPS at 78K)
- [ ] GitHub Pages deployment
- [ ] README with screenshots/GIF
- [ ] Social announcement

## Open Questions

- [x] Lobster style → Procedural low-poly (~340 triangles)
- [x] Camera behavior → Continuous auto-zoom (no jarring milestone zoom)
- [x] Skybox theme → Deep ocean with bioluminescent core
- [ ] Audio style: Ambient electronic or ocean sounds?
- [ ] Hosting: GitHub Pages or itch.io?

## Resources

- [moltbot/moltbot](https://github.com/moltbot/moltbot) - The project we're celebrating
- [star-history.com](https://star-history.com) - Reference for star history visualization
- [Godot MultiMesh docs](https://docs.godotengine.org/en/stable/classes/class_multimesh.html)
