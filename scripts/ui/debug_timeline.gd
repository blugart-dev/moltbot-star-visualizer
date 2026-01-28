extends Control
## Debug UI for testing timeline scrubbing.
##
## Provides a slider to scrub through the star history and displays
## the current date and star count. This is a temporary debug tool
## until the full timeline UI is implemented.

@onready var _slider: HSlider = $HSlider
@onready var _label: Label = $Label
@onready var _coordinator: Node = get_node_or_null("/root/Main/VisualizationCoordinator")


func _ready() -> void:
	_setup_slider()
	_connect_signals()


func _setup_slider() -> void:
	_slider.min_value = 0.0
	_slider.max_value = 1.0
	_slider.step = 0.001
	_slider.value = 0.0


func _connect_signals() -> void:
	_slider.value_changed.connect(_on_slider_changed)

	if _coordinator:
		_coordinator.date_updated.connect(_on_date_updated)


func _on_slider_changed(value: float) -> void:
	if _coordinator:
		_coordinator.set_progress(value)


func _on_date_updated(date: String, star_count: int) -> void:
	_label.text = "%s | %d stars" % [date, star_count]
