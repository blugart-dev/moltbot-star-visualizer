extends Camera3D
## Orbit camera with mouse and touch controls for viewing the lobster swarm.
##
## Mouse: Left-drag to orbit, scroll to zoom.
## Touch: Single-finger drag to orbit, pinch to zoom.
## Auto-zoom: Continuously adjusts distance to keep swarm visible while playing.

@export var orbit_speed: float = 0.005
@export var zoom_speed: float = 2.0
@export var pinch_zoom_speed: float = 0.01
@export var min_distance: float = 5.0
@export var max_distance: float = 100.0
@export var min_elevation: float = -80.0
@export var max_elevation: float = 80.0

## Padding multiplier for auto-zoom (1.5 = 50% margin around swarm).
@export var auto_zoom_padding: float = 1.8

## Speed of auto-zoom adjustment (lower = smoother).
@export var auto_zoom_speed: float = 2.0

## Whether auto-zoom is currently active.
var auto_zoom_enabled: bool = true

var _distance: float = 20.0
var _target_distance: float = 20.0
var _azimuth: float = 0.0
var _elevation: float = 30.0
var _dragging: bool = false
var _user_zooming: bool = false
var _user_zoom_cooldown: float = 0.0

var _touch_points: Dictionary = {}
var _last_pinch_distance: float = 0.0


func _ready() -> void:
	_update_camera_position()


func _process(delta: float) -> void:
	# Cooldown after user manual zoom
	if _user_zoom_cooldown > 0.0:
		_user_zoom_cooldown -= delta
		return

	# Smoothly move toward target distance when auto-zoom is active
	if auto_zoom_enabled and not _dragging:
		var diff := _target_distance - _distance
		if absf(diff) > 0.01:
			_distance += diff * auto_zoom_speed * delta
			_distance = clampf(_distance, min_distance, max_distance)
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
	_target_distance = _distance  # Sync target with manual zoom
	_user_zoom_cooldown = 2.0  # Pause auto-zoom for 2 seconds after manual zoom
	_update_camera_position()


func _update_camera_position() -> void:
	var elevation_rad := deg_to_rad(_elevation)
	var azimuth_rad := _azimuth

	var x := _distance * cos(elevation_rad) * sin(azimuth_rad)
	var y := _distance * sin(elevation_rad)
	var z := _distance * cos(elevation_rad) * cos(azimuth_rad)

	global_position = Vector3(x, y, z)
	look_at(Vector3.ZERO, Vector3.UP)


## Updates the target distance based on swarm radius.
## Called when star count changes to keep swarm visible.
func update_for_swarm_radius(radius: float) -> void:
	if radius <= 0.0:
		_target_distance = min_distance
		return

	# Calculate distance needed to see the swarm with padding
	_target_distance = radius * auto_zoom_padding
	_target_distance = clampf(_target_distance, min_distance, max_distance)
