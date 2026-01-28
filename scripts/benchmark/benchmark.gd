extends Node3D
## Benchmark scene for testing MultiMesh rendering performance.
##
## Spawns configurable number of lobster instances and displays FPS.
## Used to verify performance targets are met before full implementation.

const PositionCalculatorScript := preload("res://scripts/core/position_calculator.gd")

## Number of instances to spawn for benchmarking.
@export var instance_count: int = 10000

## Reference to the LobsterManager node.
@onready var _lobster_manager: Node3D = $World/LobsterManager

## Reference to the FPS display label.
@onready var _fps_label: Label = $UI/FPSLabel

## Reference to the instance count label.
@onready var _count_label: Label = $UI/CountLabel

## Reference to the camera for auto-positioning.
@onready var _camera: Camera3D = $World/Camera3D

var _frame_times: Array[float] = []
var _min_fps: float = INF
var _max_fps: float = 0.0
var _report_timer: float = 0.0
var _has_printed_final: bool = false


func _ready() -> void:
	_setup_benchmark()


func _process(delta: float) -> void:
	_update_fps_display(delta)


func _setup_benchmark() -> void:
	# Set instance count and position all lobsters
	_lobster_manager.set_instance_count(instance_count)

	var transforms := PositionCalculatorScript.calculate_positions(instance_count)
	for i in range(transforms.size()):
		_lobster_manager.set_instance_transform(i, transforms[i])
		# Set custom data with random animation phase
		var phase := randf()
		_lobster_manager.set_instance_custom_data(i, Color(phase, 1.0, 0.5, 1.0))

	# Position camera based on swarm radius
	var swarm_radius := PositionCalculatorScript.get_swarm_radius(instance_count)
	_camera.position = Vector3(0, swarm_radius * 0.5, swarm_radius * 2.0)
	_camera.look_at(Vector3.ZERO)

	_count_label.text = "Instances: %d" % instance_count
	print("Benchmark started with %d instances" % instance_count)


func _update_fps_display(delta: float) -> void:
	var fps := Engine.get_frames_per_second()

	# Track min/max after warmup (first 60 frames)
	if Engine.get_frames_drawn() > 60:
		_frame_times.append(delta)
		_min_fps = minf(_min_fps, fps)
		_max_fps = maxf(_max_fps, fps)

	# Calculate average from last 60 frames
	if _frame_times.size() > 60:
		_frame_times.remove_at(0)

	var avg_fps := 0.0
	if _frame_times.size() > 0:
		var total_time := 0.0
		for t in _frame_times:
			total_time += t
		avg_fps = _frame_times.size() / total_time

	_fps_label.text = "FPS: %d (avg: %.1f, min: %.1f, max: %.1f)" % [
		fps,
		avg_fps if avg_fps > 0 else fps,
		_min_fps if _min_fps != INF else fps,
		_max_fps if _max_fps > 0 else fps
	]

	# Print FPS report every 5 seconds for CLI visibility
	_report_timer += delta
	if _report_timer >= 5.0 and Engine.get_frames_drawn() > 120:
		print("[BENCHMARK] Instances: %d | FPS: %d | Avg: %.1f | Min: %.1f | Max: %.1f" % [
			instance_count,
			fps,
			avg_fps if avg_fps > 0 else fps,
			_min_fps if _min_fps != INF else fps,
			_max_fps if _max_fps > 0 else fps
		])
		_report_timer = 0.0

		# Print final report after 10 seconds of stable data
		if Engine.get_frames_drawn() > 600 and not _has_printed_final:
			_has_printed_final = true
			print("")
			print("=== FINAL BENCHMARK RESULT ===")
			print("Instance count: %d" % instance_count)
			print("Average FPS: %.1f" % avg_fps)
			print("Min FPS: %.1f" % _min_fps)
			print("Max FPS: %.1f" % _max_fps)
			var target := 60.0 if OS.get_name() != "Web" else 30.0
			var passed := avg_fps >= target
			print("Target: %.0f FPS" % target)
			print("Result: %s" % ("PASS" if passed else "FAIL"))
			print("==============================")
			print("")
