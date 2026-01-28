class_name MilestoneManager
extends Node
## Detects star count milestones and triggers celebration effects.
##
## Monitors the VisualizationCoordinator's date_updated signal and emits
## milestone_reached when key thresholds are crossed. Prevents re-triggers on scrub.

## Emitted when a milestone is reached. Effects should connect to this.
signal milestone_reached(milestone: int, star_count: int)

## Star count thresholds that trigger celebrations.
const FIXED_MILESTONES: Array[int] = [1, 1000, 10000, 50000]

## Reference to the VisualizationCoordinator to monitor star counts.
@export var visualization_coordinator: Node

## Reference to the DataProvider to get total star count.
@export var data_provider: Node

var _triggered_milestones: Dictionary = {}
var _total_stars: int = 0
var _last_star_count: int = 0


func _ready() -> void:
	_auto_find_references()
	_connect_signals()


## Resets milestone tracking. Call when restarting from beginning.
func reset() -> void:
	_triggered_milestones.clear()
	_last_star_count = 0


## Returns the list of all milestone thresholds including the final count.
func get_all_milestones() -> Array[int]:
	var milestones: Array[int] = FIXED_MILESTONES.duplicate()
	if _total_stars > 0 and _total_stars not in milestones:
		milestones.append(_total_stars)
	milestones.sort()
	return milestones


func _auto_find_references() -> void:
	if not visualization_coordinator:
		visualization_coordinator = get_node_or_null("../VisualizationCoordinator")
	if not data_provider:
		data_provider = get_node_or_null("../DataProvider")


func _connect_signals() -> void:
	if visualization_coordinator and visualization_coordinator.has_signal("date_updated"):
		visualization_coordinator.date_updated.connect(_on_date_updated)

	if data_provider:
		if data_provider.is_loaded():
			_on_data_loaded()
		elif data_provider.has_signal("data_loaded"):
			data_provider.data_loaded.connect(_on_data_loaded)


func _on_data_loaded() -> void:
	if data_provider and data_provider.has_method("get_total_stars"):
		_total_stars = data_provider.get_total_stars()


func _on_date_updated(_date: String, star_count: int) -> void:
	# Only check for milestones when moving forward
	if star_count <= _last_star_count:
		_last_star_count = star_count
		return

	var milestone := _check_milestone(_last_star_count, star_count)
	_last_star_count = star_count

	if milestone > 0:
		_trigger_milestone(milestone, star_count)


func _check_milestone(previous_count: int, current_count: int) -> int:
	# Check if we crossed any milestone threshold
	for m in FIXED_MILESTONES:
		if previous_count < m and current_count >= m:
			if not _triggered_milestones.get(m, false):
				return m

	# Check final milestone (total stars)
	if _total_stars > 0:
		if previous_count < _total_stars and current_count >= _total_stars:
			if not _triggered_milestones.get(_total_stars, false):
				return _total_stars

	return 0


func _trigger_milestone(milestone: int, star_count: int) -> void:
	_triggered_milestones[milestone] = true
	# Emit signal for effects (particles, audio) to react
	milestone_reached.emit(milestone, star_count)
