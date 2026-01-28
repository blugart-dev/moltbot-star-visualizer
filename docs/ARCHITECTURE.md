# Architecture

## Overview

Moltbot Star Tracker visualizes 78,000+ GitHub stars as 3D lobsters using Godot's MultiMeshInstance3D for efficient batched rendering, with star history data pre-cached as JSON.

## Rendering Strategy

**Decision**: MultiMeshInstance3D

| Considered | Verdict | Reason |
|------------|---------|--------|
| **MultiMeshInstance3D** | **Chosen** | Idiomatic Godot, well-documented, reliable on web |
| GPU Particles | Rejected | Designed for ephemeral effects, less control |
| Hybrid/LOD | Rejected | Added complexity not needed for this scope |

### Why MultiMesh

- Batches draw calls for identical meshes
- Per-instance transforms (position, rotation, scale)
- Shader-based per-instance variation (color, animation phase)
- Works reliably with GL Compatibility renderer on web
- Readable code - good for a public learning resource

### Implementation Notes

```gdscript
## Manages all lobster instances via MultiMesh
class_name LobsterManager
extends Node3D

var multi_mesh_instance: MultiMeshInstance3D
var multi_mesh: MultiMesh

func _ready() -> void:
    _setup_multi_mesh()

func _setup_multi_mesh() -> void:
    multi_mesh = MultiMesh.new()
    multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
    multi_mesh.use_custom_data = true  # For per-instance color/phase
    multi_mesh.mesh = preload("res://assets/models/lobster.tres")

    multi_mesh_instance = MultiMeshInstance3D.new()
    multi_mesh_instance.multimesh = multi_mesh
    add_child(multi_mesh_instance)

func set_instance_count(count: int) -> void:
    multi_mesh.instance_count = count

func set_instance_transform(index: int, xform: Transform3D) -> void:
    multi_mesh.set_instance_transform(index, xform)
```

### Shader Variation

Use `INSTANCE_CUSTOM` in shaders for per-lobster variation:

```glsl
// In vertex shader
instance vec4 custom_data; // From MultiMesh custom data
varying vec4 v_custom;

void vertex() {
    v_custom = INSTANCE_CUSTOM;
    // Use v_custom.x for animation phase offset
    // Use v_custom.yzw for color tint
}
```

## Data Pipeline

**Decision**: Pre-cached JSON (no runtime API calls)

```
[One-time fetch]              [Runtime]
GitHub API → Python script → star_history.json → Godot loads → Visualization
```

### Why Pre-cached

- **No API keys in repo** - critical for public repos
- No rate limits for users who clone and run
- Works offline
- Deterministic - everyone sees the same thing
- Simple to understand

### Data Format

`data/star_history.json`:
```json
{
  "repository": "moltbot/moltbot",
  "fetched_at": "2026-01-28T12:00:00Z",
  "total_stars": 78700,
  "history": [
    {"date": "2025-05-15", "stars": 1},
    {"date": "2025-05-16", "stars": 47},
    {"date": "2025-05-17", "stars": 1523}
  ]
}
```

### Refresh Script

`scripts/tools/fetch_star_history.py` - Run manually or via GitHub Action to update cached data.

## Scene Structure

```
Main (main.tscn)
├── World
│   ├── LobsterManager        # MultiMeshInstance3D holder
│   ├── Environment           # Lighting, background
│   └── Camera3D              # With orbit/zoom controls
├── TimelineController        # Manages playback state
├── DataProvider              # Loads and serves star data
└── UI (CanvasLayer)
    ├── TimelineBar           # Scrub through history
    ├── StatsDisplay          # Current count, date
    └── Controls              # Play/pause, speed
```

## Key Systems

### LobsterManager

Responsibilities:
- Initialize MultiMesh with lobster mesh
- Spawn/update instances based on current star count
- Manage instance transforms (positioning algorithm)
- Pass per-instance data to shader (color, animation phase)

### TimelineController

Responsibilities:
- Track current date in playback
- Handle play/pause/speed controls
- Emit signals when date changes
- Support scrubbing via timeline bar

### DataProvider

Responsibilities:
- Load `star_history.json` on startup
- Provide star count for any given date
- Binary search for efficient date lookups

## Performance Budget

| Metric | Target | Notes |
|--------|--------|-------|
| Max instances | 100,000 | Headroom above current 78k |
| Desktop FPS | 60 | Primary target |
| Web FPS | 30+ | GL Compatibility renderer |
| Initial load | < 3s | JSON parse + MultiMesh setup |
| Memory (web) | < 512MB | Browser constraints |

## Web Export Considerations

- **Renderer**: GL Compatibility (WebGL 2.0)
- **Mesh complexity**: Keep lobster under 500 triangles
- **Textures**: Compress, use atlases where possible
- **JSON size**: ~2-5MB for full history (acceptable)
- **No external fetches**: Everything bundled in export

## File Organization

```
res://
├── assets/
│   ├── models/
│   │   └── lobster.tres       # Low-poly lobster mesh
│   ├── materials/
│   │   └── lobster_material.tres
│   └── shaders/
│       └── lobster_instanced.gdshader
├── data/
│   └── star_history.json      # Pre-cached star data
├── scenes/
│   ├── main.tscn
│   └── ui/
├── scripts/
│   ├── core/
│   │   ├── lobster_manager.gd
│   │   ├── timeline_controller.gd
│   │   └── data_provider.gd
│   ├── ui/
│   └── tools/
│       └── fetch_star_history.py
└── resources/
```
