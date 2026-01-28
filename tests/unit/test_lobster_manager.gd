extends GutTest
## Unit tests for LobsterManager.

const LobsterManagerScript := preload("res://scripts/core/lobster_manager.gd")

var _manager: Node3D


func before_each() -> void:
	_manager = LobsterManagerScript.new()
	_manager.max_instances = 1000  # Smaller for tests
	add_child_autofree(_manager)
	# Wait a frame for _ready to complete
	await get_tree().process_frame


func test_initial_state() -> void:
	assert_eq(_manager.get_instance_count(), 0, "Should start with zero instances")


func test_set_instance_count() -> void:
	_manager.set_instance_count(10)
	assert_eq(_manager.get_instance_count(), 10, "Should have 10 instances after setting")


func test_set_instance_count_clamped_to_max() -> void:
	_manager.set_instance_count(5000)  # Exceeds max_instances of 1000
	assert_eq(_manager.get_instance_count(), 1000, "Should clamp to max_instances")


func test_set_instance_count_clamped_to_zero() -> void:
	_manager.set_instance_count(-5)
	assert_eq(_manager.get_instance_count(), 0, "Should clamp negative to zero")


func test_set_instance_count_emits_signal() -> void:
	watch_signals(_manager)
	_manager.set_instance_count(5)
	assert_signal_emitted_with_parameters(_manager, "instance_count_changed", [5])


func test_set_instance_count_no_signal_when_unchanged() -> void:
	_manager.set_instance_count(5)
	watch_signals(_manager)
	_manager.set_instance_count(5)  # Same count
	assert_signal_not_emitted(_manager, "instance_count_changed")


func test_set_instance_transform() -> void:
	_manager.set_instance_count(5)
	var xform := Transform3D(Basis(), Vector3(1, 2, 3))
	_manager.set_instance_transform(2, xform)

	# MultiMesh may need a frame to update
	await get_tree().process_frame

	var result: Transform3D = _manager.get_instance_transform(2)
	assert_eq(result.origin, Vector3(1, 2, 3), "Transform should be set correctly")


func test_set_instance_transform_out_of_range() -> void:
	_manager.set_instance_count(5)
	# Should warn but not crash
	_manager.set_instance_transform(10, Transform3D())
	pass_test("Should handle out of range gracefully")


func test_batch_transforms() -> void:
	_manager.set_instance_count(10)

	var transforms: Array[Transform3D] = []
	for i in range(5):
		transforms.append(Transform3D(Basis(), Vector3(i, 0, 0)))

	_manager.set_instance_transforms_batch(3, transforms)

	# MultiMesh may need a frame to update
	await get_tree().process_frame

	# Verify transforms were set
	for i in range(5):
		var result: Transform3D = _manager.get_instance_transform(3 + i)
		assert_eq(result.origin.x, float(i), "Batch transform %d should be set" % i)


func test_set_instance_custom_data() -> void:
	_manager.set_instance_count(5)
	# Custom data: RGB = color tint, A = animation phase
	var custom_data := Color(1.1, 0.9, 1.0, 0.5)
	_manager.set_instance_custom_data(2, custom_data)
	# No getter for custom data, so just verify it doesn't crash
	pass_test("Should set custom data without error")


func test_set_instance_custom_data_out_of_range() -> void:
	_manager.set_instance_count(5)
	# Should warn but not crash
	_manager.set_instance_custom_data(10, Color.WHITE)
	pass_test("Should handle out of range gracefully")
