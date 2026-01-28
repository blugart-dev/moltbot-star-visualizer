class_name AudioManager
extends Node
## Manages all audio playback including ambient background and milestone sounds.
##
## Handles web browser autoplay restrictions by starting audio on user
## interaction. Provides ambient looping and tiered milestone sound effects.

signal ambient_started
signal ambient_stopped

## Background ambient audio stream (should be loopable).
@export var ambient_stream: AudioStream

## Milestone sounds ordered by intensity: small, medium, large, epic.
@export var milestone_sounds: Array[AudioStream]

## Volume for ambient background audio.
@export var ambient_volume_db: float = -12.0

## Volume for sound effects.
@export var sfx_volume_db: float = -3.0

## Fade duration for ambient audio transitions.
@export var ambient_fade_duration: float = 1.0

var _ambient_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _ambient_tween: Tween
var _user_interacted: bool = false


func _ready() -> void:
	_setup_audio_players()


func _input(event: InputEvent) -> void:
	# Track user interaction for web autoplay policy
	if not _user_interacted:
		if event is InputEventMouseButton or event is InputEventKey:
			if event.pressed:
				_user_interacted = true
				# Auto-start ambient on first interaction if not playing
				if ambient_stream and not _ambient_player.playing:
					start_ambient()


## Starts the ambient background audio with fade-in.
func start_ambient() -> void:
	if not ambient_stream:
		push_warning("AudioManager: No ambient_stream assigned")
		return

	if _ambient_player.playing:
		return

	_ambient_player.stream = ambient_stream
	_ambient_player.volume_db = -80.0
	_ambient_player.play()

	if _ambient_tween:
		_ambient_tween.kill()
	_ambient_tween = create_tween()
	_ambient_tween.tween_property(_ambient_player, "volume_db", ambient_volume_db, ambient_fade_duration)

	ambient_started.emit()


## Stops the ambient background audio with fade-out.
func stop_ambient() -> void:
	if not _ambient_player.playing:
		return

	if _ambient_tween:
		_ambient_tween.kill()
	_ambient_tween = create_tween()
	_ambient_tween.tween_property(_ambient_player, "volume_db", -80.0, ambient_fade_duration)
	_ambient_tween.tween_callback(_ambient_player.stop)

	ambient_stopped.emit()


## Plays the appropriate milestone sound based on star count.
func play_milestone_sound(milestone: int, _star_count: int = 0) -> void:
	var index := _get_sound_index(milestone)
	if index < milestone_sounds.size() and milestone_sounds[index]:
		_sfx_player.stream = milestone_sounds[index]
		_sfx_player.play()


## Returns whether ambient audio is currently playing.
func is_ambient_playing() -> bool:
	return _ambient_player.playing


func _setup_audio_players() -> void:
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.volume_db = ambient_volume_db
	_ambient_player.autoplay = false
	add_child(_ambient_player)

	# Loop ambient audio when it finishes
	_ambient_player.finished.connect(_on_ambient_finished)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.volume_db = sfx_volume_db
	add_child(_sfx_player)


func _on_ambient_finished() -> void:
	# Restart ambient for seamless looping
	if ambient_stream:
		_ambient_player.play()


func _get_sound_index(milestone: int) -> int:
	if milestone >= 50000:
		return 3  # Epic
	elif milestone >= 10000:
		return 2  # Large
	elif milestone >= 1000:
		return 1  # Medium
	return 0  # Small
