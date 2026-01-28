extends Camera3D
## Orbit camera with mouse controls for viewing the lobster swarm.
##
## Left-click drag to orbit around the origin. Scroll to zoom in/out.

@export var orbit_speed: float = 0.005
@export var zoom_speed: float = 2.0
@export var min_distance: float = 5.0
@export var max_distance: float = 100.0
@export var min_elevation: float = -80.0
@export var max_elevation: float = 80.0

var _distance: float = 20.0
var _azimuth: float = 0.0
var _elevation: float = 30.0
var _dragging: bool = false


func _ready() -> void:
	_update_camera_position()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom(-1)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_zoom(1)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not _dragging:
		return

	_azimuth -= event.relative.x * orbit_speed
	_elevation += event.relative.y * orbit_speed * 100.0
	_elevation = clampf(_elevation, min_elevation, max_elevation)

	_update_camera_position()


func _zoom(direction: float) -> void:
	_distance += direction * zoom_speed
	_distance = clampf(_distance, min_distance, max_distance)
	_update_camera_position()


func _update_camera_position() -> void:
	var elevation_rad := deg_to_rad(_elevation)
	var azimuth_rad := _azimuth

	var x := _distance * cos(elevation_rad) * sin(azimuth_rad)
	var y := _distance * sin(elevation_rad)
	var z := _distance * cos(elevation_rad) * cos(azimuth_rad)

	global_position = Vector3(x, y, z)
	look_at(Vector3.ZERO, Vector3.UP)
