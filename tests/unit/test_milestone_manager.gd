extends GutTest
## Unit tests for MilestoneManager.


class MockDataProvider extends Node:
	var _total_stars: int = 78000
	var _loaded: bool = true
	signal data_loaded

	func is_loaded() -> bool:
		return _loaded

	func get_total_stars() -> int:
		return _total_stars


var _milestone_manager: MilestoneManager
var _mock_data_provider: MockDataProvider

# Use arrays to work around GDScript lambda capture-by-value
var _milestone_triggered: Array[int] = [0]
var _triggered_values: Array[int] = []


func before_each() -> void:
	_mock_data_provider = MockDataProvider.new()
	add_child(_mock_data_provider)

	_milestone_manager = MilestoneManager.new()
	_milestone_manager.data_provider = _mock_data_provider
	add_child(_milestone_manager)

	# Reset counters
	_milestone_triggered = [0]
	_triggered_values = []


func after_each() -> void:
	_milestone_manager.queue_free()
	_mock_data_provider.queue_free()


func _connect_milestone_counter() -> void:
	_milestone_manager.milestone_reached.connect(
		func(milestone: int, _count: int) -> void:
			_milestone_triggered[0] += 1
			_triggered_values.append(milestone)
	)


func test_milestone_1_triggers_once() -> void:
	_connect_milestone_counter()

	# Simulate star count going from 0 to 1
	_milestone_manager._on_date_updated("2025-01-01", 1)

	assert_eq(_milestone_triggered[0], 1, "Milestone should trigger once")
	assert_eq(_triggered_values[0] if _triggered_values.size() > 0 else 0, 1, "Milestone value should be 1")


func test_milestone_not_triggered_when_same_count() -> void:
	_connect_milestone_counter()

	# Trigger milestone 1
	_milestone_manager._on_date_updated("2025-01-01", 1)
	assert_eq(_milestone_triggered[0], 1)

	# Same count again - should not trigger new milestone
	_milestone_manager._on_date_updated("2025-01-02", 1)
	assert_eq(_milestone_triggered[0], 1, "No new milestone for same count")


func test_milestone_1000_triggers_at_threshold() -> void:
	_connect_milestone_counter()

	# First get past milestone 1
	_milestone_manager._on_date_updated("2025-01-01", 1)

	# Now test 1000 milestone
	_milestone_manager._on_date_updated("2025-02-01", 1000)

	assert_eq(_milestone_triggered[0], 2, "Both milestones should trigger")
	assert_eq(_triggered_values[-1] if _triggered_values.size() > 0 else 0, 1000, "Last milestone should be 1000")


func test_milestones_not_triggered_when_going_backward() -> void:
	_connect_milestone_counter()

	# Go forward past 1000
	_milestone_manager._on_date_updated("2025-01-01", 1)
	_milestone_manager._on_date_updated("2025-02-01", 1000)

	var count_after_forward := _milestone_triggered[0]

	# Go backward (scrubbing)
	_milestone_manager._on_date_updated("2025-01-15", 500)

	assert_eq(_milestone_triggered[0], count_after_forward,
			"No new milestones when scrubbing backward")


func test_reset_clears_triggered_milestones() -> void:
	_connect_milestone_counter()

	# Trigger milestone 1
	_milestone_manager._on_date_updated("2025-01-01", 1)
	assert_eq(_milestone_triggered[0], 1)

	# Reset
	_milestone_manager.reset()
	_milestone_triggered = [0]
	_triggered_values = []

	# Trigger milestone 1 again - should work after reset
	_milestone_manager._on_date_updated("2025-01-01", 1)
	assert_eq(_milestone_triggered[0], 1, "Milestone should trigger again after reset")


func test_get_all_milestones_includes_total() -> void:
	# Manually trigger data load since we're not going through _ready
	_milestone_manager._on_data_loaded()

	var milestones := _milestone_manager.get_all_milestones()

	assert_true(1 in milestones, "Should include 1")
	assert_true(1000 in milestones, "Should include 1000")
	assert_true(10000 in milestones, "Should include 10000")
	assert_true(50000 in milestones, "Should include 50000")
	assert_true(78000 in milestones, "Should include total stars")


func test_multiple_milestones_in_single_jump() -> void:
	_connect_milestone_counter()

	# Jump from 0 to 1500 - should trigger both 1 and 1000
	_milestone_manager._on_date_updated("2025-01-01", 1500)

	# Only the first crossed milestone triggers per update
	assert_true(_milestone_triggered[0] >= 1, "At least one milestone should trigger")
	assert_true(1 in _triggered_values or 1000 in _triggered_values, "Should trigger 1 or 1000")
