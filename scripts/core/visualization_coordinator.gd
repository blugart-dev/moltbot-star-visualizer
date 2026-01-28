class_name VisualizationCoordinator
extends Node
## Coordinates DataProvider and LobsterManager for date-based visualization.
##
## This is the integration layer that connects star history data to the
## visual lobster display. When the date changes, it updates the lobster
## count and positions accordingly.

## Emitted when the visualization updates for a new date.
signal date_updated(date: String, star_count: int)

## Reference to the DataProvider node.
@export var data_provider: Node

## Reference to the LobsterManager node.
@export var lobster_manager: Node3D

var _current_date: String = ""
var _current_count: int = 0


func _ready() -> void:
	_auto_find_references()
	_connect_signals()

	# Initialize to first date once data is loaded
	if data_provider and data_provider.is_loaded():
		_initialize_visualization()
	elif data_provider:
		data_provider.data_loaded.connect(_initialize_visualization)


## Updates the visualization to show stars for the given date.
func set_date(date: String) -> void:
	if not data_provider or not lobster_manager:
		push_warning("VisualizationCoordinator: Missing data_provider or lobster_manager")
		return

	if date == _current_date:
		return

	_current_date = date
	var star_count: int = data_provider.get_star_count(date)
	_update_lobster_count(star_count)
	date_updated.emit(date, star_count)


## Updates the visualization based on a normalized progress value (0.0 to 1.0).
## Useful for timeline scrubbing.
func set_progress(progress: float) -> void:
	if not data_provider:
		return

	progress = clampf(progress, 0.0, 1.0)
	var history_size: int = data_provider.get_history_size()
	if history_size == 0:
		return

	var index: int = int(progress * (history_size - 1))
	var date: String = data_provider.get_date_at_index(index)
	set_date(date)


## Returns the current date being displayed.
func get_current_date() -> String:
	return _current_date


## Returns the current star count being displayed.
func get_current_count() -> int:
	return _current_count


func _auto_find_references() -> void:
	if not data_provider:
		data_provider = get_node_or_null("../DataProvider")
	if not lobster_manager:
		lobster_manager = get_node_or_null("../World/LobsterManager")


func _connect_signals() -> void:
	if lobster_manager and lobster_manager.has_signal("instance_count_changed"):
		if not lobster_manager.instance_count_changed.is_connected(_on_instance_count_changed):
			lobster_manager.instance_count_changed.connect(_on_instance_count_changed)


func _initialize_visualization() -> void:
	if not data_provider:
		return

	var first_date: String = data_provider.get_first_date()
	if first_date != "":
		set_date(first_date)


func _update_lobster_count(count: int) -> void:
	if not lobster_manager:
		return

	var old_count: int = lobster_manager.get_instance_count()
	lobster_manager.set_instance_count(count)

	# Only recalculate positions for new instances
	if count > old_count:
		_position_new_instances(old_count, count)

	_current_count = count


func _position_new_instances(start_index: int, end_count: int) -> void:
	# Calculate positions for new instances using PositionCalculator
	var transforms: Array[Transform3D] = PositionCalculator.calculate_positions(end_count)

	# Apply transforms for new instances
	for i in range(start_index, end_count):
		lobster_manager.set_instance_transform(i, transforms[i])
		# Set random custom data for shader variation
		var custom_data := Color(
			randf(),  # Animation phase
			0.8 + randf() * 0.2,  # R tint
			0.2 + randf() * 0.2,  # G tint
			0.1 + randf() * 0.1   # B tint
		)
		lobster_manager.set_instance_custom_data(i, custom_data)


func _on_instance_count_changed(count: int) -> void:
	_current_count = count
