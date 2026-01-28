extends Control
## Timeline UI with playback controls, speed selection, and scrubbing.
##
## Provides play/pause button, speed selector dropdown, timeline slider,
## and date/count display. Connects to TimelineController for state management.

## Background color for the timeline bar (darker for contrast on light sky).
const BACKGROUND_COLOR := Color(0.12, 0.14, 0.18, 0.92)

## Accent color for highlighted elements (vibrant lobster red).
const ACCENT_COLOR := Color(0.9, 0.2, 0.1)

## Text color for labels.
const TEXT_COLOR := Color(1.0, 1.0, 1.0)

@onready var _play_button: Button = $HBoxContainer/ControlsGroup/PlayButton
@onready var _speed_selector: OptionButton = $HBoxContainer/ControlsGroup/SpeedSelector
@onready var _slider: HSlider = $HBoxContainer/HSlider
@onready var _date_label: Label = $HBoxContainer/InfoGroup/DateLabel
@onready var _star_icon: Label = $HBoxContainer/InfoGroup/StarIcon
@onready var _count_label: Label = $HBoxContainer/InfoGroup/CountLabel
@onready var _separator1: VSeparator = $HBoxContainer/Separator1
@onready var _separator2: VSeparator = $HBoxContainer/Separator2
@onready var _separator3: VSeparator = $HBoxContainer/InfoGroup/Separator3

var _timeline_controller: Node
var _coordinator: Node
var _is_scrubbing: bool = false


func _ready() -> void:
	_apply_styling()
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


func _apply_styling() -> void:
	# Create semi-transparent rounded background
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = BACKGROUND_COLOR
	bg_style.corner_radius_top_left = 12
	bg_style.corner_radius_top_right = 12
	bg_style.corner_radius_bottom_left = 0
	bg_style.corner_radius_bottom_right = 0
	add_theme_stylebox_override("panel", bg_style)

	# Style labels
	_date_label.add_theme_color_override("font_color", TEXT_COLOR.darkened(0.2))
	_date_label.add_theme_font_size_override("font_size", 14)

	# Star icon styling
	_star_icon.add_theme_color_override("font_color", ACCENT_COLOR)
	_star_icon.add_theme_font_size_override("font_size", 18)

	# Count label - prominent accent color
	_count_label.add_theme_color_override("font_color", ACCENT_COLOR)
	_count_label.add_theme_font_size_override("font_size", 18)

	# Style separators - subtle dividers
	_style_separators()

	# Style play button
	_style_play_button()

	# Style speed selector
	_style_speed_selector()

	# Style slider
	_style_slider()


func _style_play_button() -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.22, 0.28, 0.9)
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.corner_radius_bottom_right = 6

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = Color(0.28, 0.3, 0.38, 1.0)

	var pressed_style := normal_style.duplicate()
	pressed_style.bg_color = ACCENT_COLOR.darkened(0.1)

	_play_button.add_theme_stylebox_override("normal", normal_style)
	_play_button.add_theme_stylebox_override("hover", hover_style)
	_play_button.add_theme_stylebox_override("pressed", pressed_style)
	_play_button.add_theme_color_override("font_color", TEXT_COLOR)
	_play_button.add_theme_color_override("font_hover_color", TEXT_COLOR)
	_play_button.add_theme_color_override("font_pressed_color", TEXT_COLOR)

	# Center the text
	_play_button.alignment = HORIZONTAL_ALIGNMENT_CENTER


func _style_speed_selector() -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.22, 0.28, 0.9)
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.corner_radius_bottom_right = 6

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = Color(0.28, 0.3, 0.38, 1.0)

	_speed_selector.add_theme_stylebox_override("normal", normal_style)
	_speed_selector.add_theme_stylebox_override("hover", hover_style)
	_speed_selector.add_theme_color_override("font_color", TEXT_COLOR)
	_speed_selector.add_theme_color_override("font_hover_color", TEXT_COLOR)
	_speed_selector.add_theme_font_size_override("font_size", 13)

	# Center the text
	_speed_selector.alignment = HORIZONTAL_ALIGNMENT_CENTER


func _style_separators() -> void:
	# Use StyleBoxFlat for more reliable rendering
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(1.0, 1.0, 1.0, 0.4)
	sep_style.content_margin_left = 1
	sep_style.content_margin_right = 1

	_separator1.add_theme_stylebox_override("separator", sep_style)
	_separator2.add_theme_stylebox_override("separator", sep_style)

	# Set minimum width so they're actually visible
	_separator1.custom_minimum_size.x = 2
	_separator2.custom_minimum_size.x = 2

	# Inner separator between date and star count
	var inner_sep := StyleBoxFlat.new()
	inner_sep.bg_color = Color(1.0, 1.0, 1.0, 0.25)
	inner_sep.content_margin_left = 1
	inner_sep.content_margin_right = 1
	_separator3.add_theme_stylebox_override("separator", inner_sep)
	_separator3.custom_minimum_size.x = 2


func _style_slider() -> void:
	# Slider track (background)
	var grabber_area := StyleBoxFlat.new()
	grabber_area.bg_color = Color(0.25, 0.27, 0.32, 0.8)
	grabber_area.corner_radius_top_left = 4
	grabber_area.corner_radius_top_right = 4
	grabber_area.corner_radius_bottom_left = 4
	grabber_area.corner_radius_bottom_right = 4
	grabber_area.content_margin_top = 4
	grabber_area.content_margin_bottom = 4

	# Slider fill (progress)
	var grabber_area_highlight := StyleBoxFlat.new()
	grabber_area_highlight.bg_color = ACCENT_COLOR.darkened(0.2)
	grabber_area_highlight.corner_radius_top_left = 4
	grabber_area_highlight.corner_radius_top_right = 4
	grabber_area_highlight.corner_radius_bottom_left = 4
	grabber_area_highlight.corner_radius_bottom_right = 4
	grabber_area_highlight.content_margin_top = 4
	grabber_area_highlight.content_margin_bottom = 4

	# Grabber (thumb)
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = ACCENT_COLOR
	grabber.corner_radius_top_left = 8
	grabber.corner_radius_top_right = 8
	grabber.corner_radius_bottom_left = 8
	grabber.corner_radius_bottom_right = 8

	var grabber_highlight := grabber.duplicate()
	grabber_highlight.bg_color = ACCENT_COLOR.lightened(0.2)

	_slider.add_theme_stylebox_override("slider", grabber_area)
	_slider.add_theme_stylebox_override("grabber_area", grabber_area)
	_slider.add_theme_stylebox_override("grabber_area_highlight", grabber_area_highlight)
	_slider.add_theme_icon_override("grabber", _create_grabber_texture(ACCENT_COLOR))
	_slider.add_theme_icon_override("grabber_highlight", _create_grabber_texture(ACCENT_COLOR.lightened(0.2)))


func _create_grabber_texture(color: Color) -> ImageTexture:
	# Create a circular grabber texture
	var size := 16
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	var radius := size / 2.0 - 1

	for x in range(size):
		for y in range(size):
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius:
				# Smooth edge with anti-aliasing
				var alpha := clampf(radius - dist + 0.5, 0.0, 1.0)
				img.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	return ImageTexture.create_from_image(img)


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
