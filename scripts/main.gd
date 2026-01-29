extends Node
## Main scene coordinator for signal connections.
##
## Wires up cross-system signals for auto-zoom.

@onready var _coordinator: Node = $VisualizationCoordinator
@onready var _camera: Camera3D = $World/Camera3D


func _ready() -> void:
	call_deferred("_connect_signals")


func _connect_signals() -> void:
	_connect_auto_zoom()


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
