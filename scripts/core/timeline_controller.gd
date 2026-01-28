class_name TimelineController
extends Node
## Controls timeline playback state, speed, and progress.
##
## Owns the playback state machine and drives the visualization over time.
## Emits signals when state changes so UI can react accordingly.

## Emitted when play/pause state changes.
signal play_state_changed(is_playing: bool)

## Emitted when playback speed changes.
signal speed_changed(speed: float)

## Emitted when progress changes (from playback or scrubbing).
signal progress_changed(progress: float)

## Available speed presets for playback.
const SPEED_PRESETS: Array[float] = [0.5, 1.0, 2.0, 5.0, 10.0]

## Duration in seconds for full playback at 1x speed.
@export var base_duration: float = 60.0

## Reference to VisualizationCoordinator (auto-found if not set).
@export var visualization_coordinator: Node

var _is_playing: bool = false
var _speed: float = 1.0
var _progress: float = 0.0


func _ready() -> void:
	_auto_find_references()


func _process(delta: float) -> void:
	if not _is_playing:
		return

	var progress_delta: float = delta / base_duration * _speed
	_progress = minf(_progress + progress_delta, 1.0)

	if visualization_coordinator:
		visualization_coordinator.set_progress(_progress)

	progress_changed.emit(_progress)

	if _progress >= 1.0:
		pause()


## Start playback from current position.
func play() -> void:
	if _is_playing:
		return

	# If at end, restart from beginning
	if _progress >= 1.0:
		_progress = 0.0

	_is_playing = true
	play_state_changed.emit(true)


## Pause playback at current position.
func pause() -> void:
	if not _is_playing:
		return

	_is_playing = false
	play_state_changed.emit(false)


## Toggle between play and pause.
func toggle_play() -> void:
	if _is_playing:
		pause()
	else:
		play()


## Returns true if currently playing.
func is_playing() -> bool:
	return _is_playing


## Set playback speed multiplier.
func set_speed(speed: float) -> void:
	speed = clampf(speed, SPEED_PRESETS[0], SPEED_PRESETS[SPEED_PRESETS.size() - 1])
	if is_equal_approx(_speed, speed):
		return

	_speed = speed
	speed_changed.emit(_speed)


## Returns current playback speed.
func get_speed() -> float:
	return _speed


## Cycle to next speed preset.
func next_speed() -> void:
	var current_index: int = -1
	for i in range(SPEED_PRESETS.size()):
		if is_equal_approx(SPEED_PRESETS[i], _speed):
			current_index = i
			break

	var next_index: int = (current_index + 1) % SPEED_PRESETS.size()
	set_speed(SPEED_PRESETS[next_index])


## Set progress directly (0.0 to 1.0). Pauses playback.
func set_progress(progress: float) -> void:
	progress = clampf(progress, 0.0, 1.0)

	# Pause when scrubbing
	if _is_playing:
		_is_playing = false
		play_state_changed.emit(false)

	_progress = progress

	if visualization_coordinator:
		visualization_coordinator.set_progress(_progress)

	progress_changed.emit(_progress)


## Returns current progress (0.0 to 1.0).
func get_progress() -> float:
	return _progress


## Jump to start of timeline.
func go_to_start() -> void:
	set_progress(0.0)


## Jump to end of timeline.
func go_to_end() -> void:
	set_progress(1.0)


func _auto_find_references() -> void:
	if not visualization_coordinator:
		visualization_coordinator = get_node_or_null("../VisualizationCoordinator")
