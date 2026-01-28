extends GutTest
## Unit tests for VisualizationCoordinator.

const CoordinatorScript := preload("res://scripts/core/visualization_coordinator.gd")
const DataProviderScript := preload("res://scripts/core/data_provider.gd")
const LobsterManagerScript := preload("res://scripts/core/lobster_manager.gd")

var _coordinator: Node
var _data_provider: Node
var _lobster_manager: Node3D


func before_each() -> void:
	# Create instances
	_data_provider = DataProviderScript.new()
	_lobster_manager = LobsterManagerScript.new()
	_coordinator = CoordinatorScript.new()

	# Manually load data
	_data_provider._load_data()

	# Wire up references
	_coordinator.data_provider = _data_provider
	_coordinator.lobster_manager = _lobster_manager

	# Add to tree so _ready runs for lobster manager
	add_child_autofree(_lobster_manager)
	add_child_autofree(_data_provider)
	add_child_autofree(_coordinator)


# --- Initialization Tests ---

func test_coordinator_initializes_with_references() -> void:
	assert_not_null(_coordinator.data_provider, "Should have data_provider reference")
	assert_not_null(_coordinator.lobster_manager, "Should have lobster_manager reference")


func test_coordinator_starts_at_first_date() -> void:
	# Wait a frame for initialization
	await get_tree().process_frame

	var expected_first_date: String = _data_provider.get_first_date()
	assert_eq(_coordinator.get_current_date(), expected_first_date,
		"Should initialize to first date")


# --- Date Setting Tests ---

func test_set_date_updates_lobster_count() -> void:
	var test_date: String = _data_provider.get_last_date()
	var expected_count: int = _data_provider.get_star_count(test_date)

	_coordinator.set_date(test_date)

	assert_eq(_lobster_manager.get_instance_count(), expected_count,
		"Lobster count should match star count for date")


func test_set_date_emits_signal() -> void:
	watch_signals(_coordinator)

	var test_date: String = _data_provider.get_date_at_index(5)
	_coordinator.set_date(test_date)

	assert_signal_emitted(_coordinator, "date_updated",
		"Should emit date_updated signal")


func test_set_same_date_does_not_update() -> void:
	var test_date: String = _data_provider.get_first_date()
	_coordinator.set_date(test_date)

	watch_signals(_coordinator)
	_coordinator.set_date(test_date)  # Same date again

	assert_signal_not_emitted(_coordinator, "date_updated",
		"Should not emit signal for same date")


# --- Progress Tests ---

func test_set_progress_zero_is_first_date() -> void:
	_coordinator.set_progress(0.0)

	var expected: String = _data_provider.get_first_date()
	assert_eq(_coordinator.get_current_date(), expected,
		"Progress 0.0 should be first date")


func test_set_progress_one_is_last_date() -> void:
	_coordinator.set_progress(1.0)

	var expected: String = _data_provider.get_last_date()
	assert_eq(_coordinator.get_current_date(), expected,
		"Progress 1.0 should be last date")


func test_set_progress_half_is_middle() -> void:
	_coordinator.set_progress(0.5)

	var history_size: int = _data_provider.get_history_size()
	var mid_index: int = int(0.5 * (history_size - 1))
	var expected: String = _data_provider.get_date_at_index(mid_index)

	assert_eq(_coordinator.get_current_date(), expected,
		"Progress 0.5 should be middle date")


func test_set_progress_clamps_values() -> void:
	_coordinator.set_progress(-0.5)
	assert_eq(_coordinator.get_current_date(), _data_provider.get_first_date(),
		"Negative progress should clamp to first date")

	_coordinator.set_progress(1.5)
	assert_eq(_coordinator.get_current_date(), _data_provider.get_last_date(),
		"Progress > 1 should clamp to last date")


# --- Count Tests ---

func test_current_count_matches_lobster_manager() -> void:
	_coordinator.set_progress(0.5)

	assert_eq(_coordinator.get_current_count(), _lobster_manager.get_instance_count(),
		"Current count should match lobster manager")


func test_scrubbing_updates_count_correctly() -> void:
	# Scrub from start to end
	_coordinator.set_progress(0.0)
	var start_count: int = _coordinator.get_current_count()

	_coordinator.set_progress(1.0)
	var end_count: int = _coordinator.get_current_count()

	assert_lt(start_count, end_count,
		"End count should be greater than start count")
	assert_eq(end_count, _data_provider.get_total_stars(),
		"End count should equal total stars")


# --- Performance Tests ---

func test_rapid_scrubbing_performance() -> void:
	var start_time: int = Time.get_ticks_msec()

	# Simulate rapid scrubbing
	for i: int in range(100):
		var progress: float = float(i) / 100.0
		_coordinator.set_progress(progress)

	var elapsed: int = Time.get_ticks_msec() - start_time

	# Should complete in under 2 seconds
	assert_lt(elapsed, 2000,
		"100 progress updates should be fast (took %dms)" % elapsed)


func test_increasing_count_positions_new_instances() -> void:
	# Start with some instances
	_coordinator.set_progress(0.0)
	var initial_count: int = _lobster_manager.get_instance_count()

	# Move forward to add more
	_coordinator.set_progress(0.5)
	var new_count: int = _lobster_manager.get_instance_count()

	# Check that new instances have non-zero transforms
	if new_count > initial_count:
		var transform: Transform3D = _lobster_manager.get_instance_transform(new_count - 1)
		assert_ne(transform.origin, Vector3.ZERO,
			"New instances should have positioned transforms")
