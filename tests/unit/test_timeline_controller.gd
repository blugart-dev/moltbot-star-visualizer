extends GutTest
## Unit tests for TimelineController.

const TimelineControllerScript := preload("res://scripts/core/timeline_controller.gd")
const VisualizationCoordinatorScript := preload("res://scripts/core/visualization_coordinator.gd")
const DataProviderScript := preload("res://scripts/core/data_provider.gd")
const LobsterManagerScript := preload("res://scripts/core/lobster_manager.gd")

var _controller: Node
var _coordinator: Node
var _data_provider: Node
var _lobster_manager: Node3D


func before_each() -> void:
	_data_provider = DataProviderScript.new()
	_lobster_manager = LobsterManagerScript.new()
	_coordinator = VisualizationCoordinatorScript.new()
	_controller = TimelineControllerScript.new()

	_data_provider._load_data()

	_coordinator.data_provider = _data_provider
	_coordinator.lobster_manager = _lobster_manager
	_controller.visualization_coordinator = _coordinator

	add_child_autofree(_lobster_manager)
	add_child_autofree(_data_provider)
	add_child_autofree(_coordinator)
	add_child_autofree(_controller)


# --- State Tests ---

func test_starts_paused() -> void:
	assert_false(_controller.is_playing(), "Should start paused")


func test_play_changes_state() -> void:
	_controller.play()
	assert_true(_controller.is_playing(), "Should be playing after play()")


func test_pause_changes_state() -> void:
	_controller.play()
	_controller.pause()
	assert_false(_controller.is_playing(), "Should be paused after pause()")


func test_toggle_play_alternates() -> void:
	assert_false(_controller.is_playing(), "Should start paused")

	_controller.toggle_play()
	assert_true(_controller.is_playing(), "Should be playing after first toggle")

	_controller.toggle_play()
	assert_false(_controller.is_playing(), "Should be paused after second toggle")


func test_play_emits_signal() -> void:
	watch_signals(_controller)
	_controller.play()
	assert_signal_emitted_with_parameters(_controller, "play_state_changed", [true])


func test_pause_emits_signal() -> void:
	_controller.play()
	watch_signals(_controller)
	_controller.pause()
	assert_signal_emitted_with_parameters(_controller, "play_state_changed", [false])


# --- Speed Tests ---

func test_default_speed_is_one() -> void:
	assert_eq(_controller.get_speed(), 1.0, "Default speed should be 1.0")


func test_set_speed_updates_value() -> void:
	_controller.set_speed(2.0)
	assert_eq(_controller.get_speed(), 2.0, "Speed should update to 2.0")


func test_set_speed_emits_signal() -> void:
	watch_signals(_controller)
	_controller.set_speed(5.0)
	assert_signal_emitted_with_parameters(_controller, "speed_changed", [5.0])


func test_set_speed_clamps_to_valid_range() -> void:
	_controller.set_speed(0.1)
	assert_eq(_controller.get_speed(), 0.5, "Speed should clamp to minimum preset")

	_controller.set_speed(100.0)
	assert_eq(_controller.get_speed(), 10.0, "Speed should clamp to maximum preset")


func test_next_speed_cycles_presets() -> void:
	assert_eq(_controller.get_speed(), 1.0, "Should start at 1.0")

	_controller.next_speed()
	assert_eq(_controller.get_speed(), 2.0, "Should cycle to 2.0")

	_controller.next_speed()
	assert_eq(_controller.get_speed(), 5.0, "Should cycle to 5.0")

	_controller.next_speed()
	assert_eq(_controller.get_speed(), 10.0, "Should cycle to 10.0")

	_controller.next_speed()
	assert_eq(_controller.get_speed(), 0.5, "Should wrap to 0.5")


# --- Progress Tests ---

func test_starts_at_zero_progress() -> void:
	assert_eq(_controller.get_progress(), 0.0, "Should start at progress 0.0")


func test_set_progress_updates_value() -> void:
	_controller.set_progress(0.5)
	assert_eq(_controller.get_progress(), 0.5, "Progress should update to 0.5")


func test_set_progress_clamps_to_range() -> void:
	_controller.set_progress(-0.5)
	assert_eq(_controller.get_progress(), 0.0, "Negative progress should clamp to 0.0")

	_controller.set_progress(1.5)
	assert_eq(_controller.get_progress(), 1.0, "Progress > 1 should clamp to 1.0")


func test_set_progress_pauses_playback() -> void:
	_controller.play()
	assert_true(_controller.is_playing(), "Should be playing")

	_controller.set_progress(0.5)
	assert_false(_controller.is_playing(), "Should pause when scrubbing")


func test_set_progress_emits_signal() -> void:
	watch_signals(_controller)
	_controller.set_progress(0.7)
	assert_signal_emitted_with_parameters(_controller, "progress_changed", [0.7])


func test_go_to_start_sets_zero() -> void:
	_controller.set_progress(0.5)
	_controller.go_to_start()
	assert_eq(_controller.get_progress(), 0.0, "go_to_start should set progress to 0.0")


func test_go_to_end_sets_one() -> void:
	_controller.go_to_end()
	assert_eq(_controller.get_progress(), 1.0, "go_to_end should set progress to 1.0")


# --- Playback Tests ---

func test_playback_increments_progress() -> void:
	_controller.play()

	# Simulate one frame at 60 FPS
	_controller._process(1.0 / 60.0)

	assert_gt(_controller.get_progress(), 0.0, "Progress should increment during playback")


func test_playback_stops_at_end() -> void:
	_controller.set_progress(0.99)
	_controller.play()

	# Simulate enough time to reach the end
	_controller._process(10.0)

	assert_false(_controller.is_playing(), "Should stop playing at end")
	assert_eq(_controller.get_progress(), 1.0, "Progress should be 1.0 at end")


func test_faster_speed_increases_rate() -> void:
	_controller.set_speed(1.0)
	_controller.play()
	_controller._process(1.0)
	var progress_at_1x: float = _controller.get_progress()

	# Reset
	_controller.pause()
	_controller.set_progress(0.0)

	_controller.set_speed(2.0)
	_controller.play()
	_controller._process(1.0)
	var progress_at_2x: float = _controller.get_progress()

	assert_almost_eq(progress_at_2x, progress_at_1x * 2.0, 0.001,
		"2x speed should progress twice as fast")


func test_play_from_end_restarts() -> void:
	_controller.set_progress(1.0)
	_controller.play()

	assert_eq(_controller.get_progress(), 0.0, "Playing from end should restart at 0.0")
	assert_true(_controller.is_playing(), "Should be playing after restart")


# --- Integration Tests ---

func test_progress_updates_coordinator() -> void:
	await get_tree().process_frame

	_controller.set_progress(0.5)

	var date: String = _coordinator.get_current_date()
	assert_ne(date, "", "Coordinator should have a date set")


func test_playback_updates_visualization() -> void:
	await get_tree().process_frame

	var initial_count: int = _coordinator.get_current_count()

	_controller.set_progress(1.0)

	var final_count: int = _coordinator.get_current_count()

	assert_gt(final_count, initial_count,
		"Scrubbing to end should increase instance count")
