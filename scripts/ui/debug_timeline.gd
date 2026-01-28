extends Control
## Timeline UI with playback controls, speed selection, and scrubbing.
##
## Provides play/pause button, speed selector dropdown, timeline slider,
## and date/count display. Connects to TimelineController for state management.

@onready var _play_button: Button = $HBoxContainer/PlayButton
@onready var _speed_selector: OptionButton = $HBoxContainer/SpeedSelector
@onready var _slider: HSlider = $HBoxContainer/HSlider
@onready var _date_label: Label = $HBoxContainer/DateLabel
@onready var _count_label: Label = $HBoxContainer/CountLabel

var _timeline_controller: Node
var _coordinator: Node
var _is_scrubbing: bool = false


func _ready() -> void:
	_setup_slider()
	call_deferred("_deferred_setup")


func _deferred_setup() -> void:
	_timeline_controller = get_node_or_null("/root/Main/TimelineController")
	_coordinator = get_node_or_null("/root/Main/VisualizationCoordinator")
	_connect_signals()
	_update_initial_state()


func _setup_slider() -> void:
	_slider.min_value = 0.0
	_slider.max_value = 1.0
	_slider.step = 0.001
	_slider.value = 0.0


func _connect_signals() -> void:
	_play_button.pressed.connect(_on_play_button_pressed)
	_speed_selector.item_selected.connect(_on_speed_selected)
	_slider.value_changed.connect(_on_slider_changed)
	_slider.drag_started.connect(_on_slider_drag_started)
	_slider.drag_ended.connect(_on_slider_drag_ended)

	if _timeline_controller:
		_timeline_controller.play_state_changed.connect(_on_play_state_changed)
		_timeline_controller.speed_changed.connect(_on_speed_changed)
		_timeline_controller.progress_changed.connect(_on_progress_changed)

	if _coordinator:
		_coordinator.date_updated.connect(_on_date_updated)


func _update_initial_state() -> void:
	_update_play_button(false)

	if _coordinator and _coordinator.get_current_date() != "":
		var date: String = _coordinator.get_current_date()
		var count: int = _coordinator.get_current_count()
		_update_date_display(date)
		_update_count_display(count)
	else:
		_date_label.text = "Loading..."
		_count_label.text = "0"


func _on_play_button_pressed() -> void:
	if _timeline_controller:
		_timeline_controller.toggle_play()


func _on_speed_selected(index: int) -> void:
	if not _timeline_controller:
		return

	var speeds: Array[float] = [0.5, 1.0, 2.0, 5.0, 10.0]
	if index >= 0 and index < speeds.size():
		_timeline_controller.set_speed(speeds[index])


func _on_slider_drag_started() -> void:
	_is_scrubbing = true


func _on_slider_drag_ended(_value_changed: bool) -> void:
	_is_scrubbing = false


func _on_slider_changed(value: float) -> void:
	if _timeline_controller and _is_scrubbing:
		_timeline_controller.set_progress(value)


func _on_play_state_changed(is_playing: bool) -> void:
	_update_play_button(is_playing)


func _on_speed_changed(speed: float) -> void:
	var speeds: Array[float] = [0.5, 1.0, 2.0, 5.0, 10.0]
	for i in range(speeds.size()):
		if is_equal_approx(speeds[i], speed):
			_speed_selector.selected = i
			break


func _on_progress_changed(progress: float) -> void:
	if not _is_scrubbing:
		_slider.value = progress


func _on_date_updated(date: String, star_count: int) -> void:
	_update_date_display(date)
	_update_count_display(star_count)


func _update_play_button(is_playing: bool) -> void:
	_play_button.text = "||" if is_playing else ">"


func _update_date_display(date: String) -> void:
	_date_label.text = _format_date(date)


func _update_count_display(count: int) -> void:
	_count_label.text = _format_number(count)


func _format_date(date: String) -> String:
	if date.is_empty():
		return ""

	var parts: PackedStringArray = date.split("-")
	if parts.size() != 3:
		return date

	var months: Array[String] = [
		"Jan", "Feb", "Mar", "Apr", "May", "Jun",
		"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
	]

	var year: String = parts[0]
	var month_index: int = parts[1].to_int() - 1
	var day: String = parts[2].lstrip("0")

	if month_index < 0 or month_index >= 12:
		return date

	return "%s %s, %s" % [months[month_index], day, year]


func _format_number(number: int) -> String:
	var result: String = ""
	var num_str: String = str(number)
	var count: int = 0

	for i in range(num_str.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = num_str[i] + result
		count += 1

	return result
