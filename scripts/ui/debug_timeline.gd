extends Control
## Debug UI for testing timeline scrubbing.
##
## Provides a slider to scrub through the star history and displays
## the current date and star count. This is a temporary debug tool
## until the full timeline UI is implemented.

@onready var _slider: HSlider = $HSlider
@onready var _label: Label = $Label

var _coordinator: Node


func _ready() -> void:
	_setup_slider()
	# Defer coordinator lookup to ensure scene tree is fully ready
	call_deferred("_deferred_setup")


func _deferred_setup() -> void:
	_coordinator = get_node_or_null("/root/Main/VisualizationCoordinator")
	_connect_signals()
	_update_initial_state()


func _setup_slider() -> void:
	_slider.min_value = 0.0
	_slider.max_value = 1.0
	_slider.step = 0.001
	_slider.value = 0.0


func _connect_signals() -> void:
	_slider.value_changed.connect(_on_slider_changed)

	if _coordinator:
		_coordinator.date_updated.connect(_on_date_updated)


func _update_initial_state() -> void:
	if _coordinator:
		var date: String = _coordinator.get_current_date()
		var count: int = _coordinator.get_current_count()
		if date != "":
			_label.text = "%s | %d stars" % [date, count]
		else:
			_label.text = "No data loaded"
	else:
		_label.text = "Coordinator not found"


func _on_slider_changed(value: float) -> void:
	if _coordinator:
		_coordinator.set_progress(value)


func _on_date_updated(date: String, star_count: int) -> void:
	_label.text = "%s | %d stars" % [date, star_count]
