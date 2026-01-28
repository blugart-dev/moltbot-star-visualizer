extends Camera3D
## Orbit camera with mouse and touch controls for viewing the lobster swarm.
##
## Mouse: Left-drag to orbit, scroll to zoom.
## Touch: Single-finger drag to orbit, pinch to zoom.

@export var orbit_speed: float = 0.005
@export var zoom_speed: float = 2.0
@export var pinch_zoom_speed: float = 0.01
@export var min_distance: float = 5.0
@export var max_distance: float = 100.0
@export var min_elevation: float = -80.0
@export var max_elevation: float = 80.0

var _distance: float = 20.0
var _azimuth: float = 0.0
var _elevation: float = 30.0
var _dragging: bool = false

var _touch_points: Dictionary = {}
var _last_pinch_distance: float = 0.0


func _ready() -> void:
	_update_camera_position()


func _unhandled_input(event: InputEvent) -> void:
	# Don't process input if mouse is over GUI
	if _is_mouse_over_gui():
		_dragging = false
		return

	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)


func _is_mouse_over_gui() -> bool:
	var viewport := get_viewport()
	if viewport:
		return viewport.gui_get_hovered_control() != null
	return false


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


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touch_points[event.index] = event.position
	else:
		_touch_points.erase(event.index)
		_last_pinch_distance = 0.0


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	_touch_points[event.index] = event.position

	if _touch_points.size() == 1:
		_azimuth -= event.relative.x * orbit_speed
		_elevation += event.relative.y * orbit_speed * 100.0
		_elevation = clampf(_elevation, min_elevation, max_elevation)
		_update_camera_position()

	elif _touch_points.size() == 2:
		var points := _touch_points.values()
		var current_distance := (points[0] as Vector2).distance_to(points[1] as Vector2)

		if _last_pinch_distance > 0.0:
			var delta := _last_pinch_distance - current_distance
			_distance += delta * pinch_zoom_speed
			_distance = clampf(_distance, min_distance, max_distance)
			_update_camera_position()

		_last_pinch_distance = current_distance


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
