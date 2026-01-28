class_name LobsterManager
extends Node3D
## Manages all lobster instances via MultiMesh for efficient batched rendering.
##
## Handles spawning, positioning, and per-instance shader data for thousands
## of lobster instances. Uses MultiMeshInstance3D for GPU-instanced rendering.

## Emitted when instance count changes.
signal instance_count_changed(count: int)

## The mesh to use for each lobster instance.
@export var lobster_mesh: Mesh

## Maximum number of instances to pre-allocate. Changing count within this
## limit won't reallocate the buffer.
@export var max_instances: int = 100000

var _multi_mesh: MultiMesh
var _multi_mesh_instance: MultiMeshInstance3D
var _current_count: int = 0
var _transforms: Array[Transform3D] = []


func _ready() -> void:
	_setup_multi_mesh()


## Returns the current number of visible instances.
func get_instance_count() -> int:
	return _current_count


## Sets the number of visible lobster instances.
## Instances beyond this count are hidden (zero scale).
func set_instance_count(count: int) -> void:
	count = clampi(count, 0, max_instances)
	if count == _current_count:
		return

	# If increasing, ensure new instances have valid transforms
	if count > _current_count:
		for i in range(_current_count, count):
			# New instances start at origin with zero scale (invisible)
			# Caller should set proper transforms after
			_multi_mesh.set_instance_transform(i, Transform3D())

	_current_count = count
	_multi_mesh.visible_instance_count = count
	instance_count_changed.emit(count)


## Sets the transform for a specific instance.
func set_instance_transform(index: int, xform: Transform3D) -> void:
	if index < 0 or index >= _current_count:
		push_warning("LobsterManager: Instance index %d out of range (count: %d)" % [index, _current_count])
		return
	_transforms[index] = xform
	_multi_mesh.set_instance_transform(index, xform)


## Sets custom data for a specific instance (used by shader).
## Convention: x = animation phase, yzw = color tint RGB.
func set_instance_custom_data(index: int, data: Color) -> void:
	if index < 0 or index >= _current_count:
		push_warning("LobsterManager: Instance index %d out of range (count: %d)" % [index, _current_count])
		return
	_multi_mesh.set_instance_custom_data(index, data)


## Gets the transform for a specific instance.
func get_instance_transform(index: int) -> Transform3D:
	if index < 0 or index >= _current_count:
		push_warning("LobsterManager: Instance index %d out of range (count: %d)" % [index, _current_count])
		return Transform3D()
	return _transforms[index]


## Batch update: set transforms for a range of instances.
## More efficient than calling set_instance_transform in a loop when
## making many changes.
func set_instance_transforms_batch(start_index: int, transforms: Array[Transform3D]) -> void:
	var end_index := start_index + transforms.size()
	if start_index < 0 or end_index > _current_count:
		push_warning("LobsterManager: Batch range [%d, %d) out of bounds (count: %d)" % [start_index, end_index, _current_count])
		return

	for i in range(transforms.size()):
		var index := start_index + i
		_transforms[index] = transforms[i]
		_multi_mesh.set_instance_transform(index, transforms[i])


func _setup_multi_mesh() -> void:
	_multi_mesh = MultiMesh.new()
	_multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	_multi_mesh.use_custom_data = true

	if lobster_mesh:
		_multi_mesh.mesh = lobster_mesh
	else:
		push_warning("LobsterManager: No lobster_mesh assigned, using placeholder")
		_multi_mesh.mesh = _create_placeholder_mesh()

	# Pre-allocate buffer for max instances, but show none initially
	_multi_mesh.instance_count = max_instances
	_multi_mesh.visible_instance_count = 0

	# Pre-allocate transform cache
	_transforms.resize(max_instances)
	for i in range(max_instances):
		_transforms[i] = Transform3D()

	_multi_mesh_instance = MultiMeshInstance3D.new()
	_multi_mesh_instance.multimesh = _multi_mesh
	add_child(_multi_mesh_instance)


func _create_placeholder_mesh() -> Mesh:
	# Simple box as placeholder until real lobster mesh exists
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.3, 1.0)  # Lobster-ish proportions

	# Use the instanced shader material for per-instance variation
	var material: ShaderMaterial = load("res://assets/materials/lobster_material.tres")
	if material:
		box.material = material
	else:
		# Fallback if material not found
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = Color(0.8, 0.3, 0.2)  # Lobster red
		box.material = fallback

	return box
