extends Node
## Main scene coordinator for signal connections.
##
## Wires up cross-system signals for auto-zoom, milestone effects, and audio.

@onready var _coordinator: Node = $VisualizationCoordinator
@onready var _milestone_manager: Node = $MilestoneManager
@onready var _audio_manager: Node = $AudioManager
@onready var _camera: Camera3D = $World/Camera3D
@onready var _particles: GPUParticles3D = $World/MilestoneParticles


func _ready() -> void:
	call_deferred("_connect_signals")


func _connect_signals() -> void:
	_connect_auto_zoom()
	_connect_milestone_effects()


func _connect_auto_zoom() -> void:
	if not _coordinator or not _camera:
		return

	if not _camera.has_method("update_for_swarm_radius"):
		return

	# Update camera zoom when star count changes
	_coordinator.date_updated.connect(_on_date_updated)


func _on_date_updated(_date: String, star_count: int) -> void:
	# Calculate swarm radius and update camera
	var radius := PositionCalculator.get_swarm_radius(star_count)
	_camera.update_for_swarm_radius(radius)


func _connect_milestone_effects() -> void:
	if not _milestone_manager:
		return

	# Particles for milestones (subtle burst)
	if _particles and _particles.has_method("trigger_burst"):
		_milestone_manager.milestone_reached.connect(_particles.trigger_burst)

	# Audio for milestones
	if _audio_manager and _audio_manager.has_method("play_milestone_sound"):
		_milestone_manager.milestone_reached.connect(_audio_manager.play_milestone_sound)
