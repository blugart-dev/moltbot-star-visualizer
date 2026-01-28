class_name PositionCalculator
extends RefCounted
## Calculates 3D positions for lobster instances using Fibonacci sphere distribution.
##
## Positions are distributed evenly in 3D space around the origin, growing
## organically as more instances are added. Uses layered spheres to maintain
## visual density as the swarm grows.

## Golden angle in radians for Fibonacci spiral distribution.
const GOLDEN_ANGLE: float = PI * (3.0 - sqrt(5.0))

## Base radius for the first layer of lobsters.
const BASE_RADIUS: float = 3.0

## Spacing multiplier between layers.
const LAYER_SPACING: float = 1.0

## Random seed for deterministic rotations.
const ROTATION_SEED: int = 12345

## Maximum rotation offset in radians for visual variety.
const MAX_ROTATION_OFFSET: float = PI * 0.25

## Number of instances per unit of sphere surface area.
## Controls density - higher means more tightly packed.
const DENSITY_FACTOR: float = 0.3


## Calculates transforms for the specified number of instances.
## Returns deterministic positions distributed in layered Fibonacci spheres.
static func calculate_positions(count: int) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	if count <= 0:
		return result

	result.resize(count)

	# Use a seeded random number generator for deterministic rotations
	var rng := RandomNumberGenerator.new()
	rng.seed = ROTATION_SEED

	var current_index: int = 0
	var layer: int = 0

	while current_index < count:
		var layer_radius := _get_layer_radius(layer)
		var layer_capacity := _get_layer_capacity(layer)
		var instances_in_layer := mini(layer_capacity, count - current_index)

		for i in range(instances_in_layer):
			var position := _fibonacci_sphere_point(i, instances_in_layer, layer_radius)
			var rotation := _calculate_rotation(position, rng)
			result[current_index] = Transform3D(rotation, position)
			current_index += 1

		layer += 1

	return result


## Calculates a single position for incremental updates.
## Returns the transform for the instance at the given index.
static func calculate_single_position(index: int, total_count: int) -> Transform3D:
	if index < 0 or index >= total_count:
		return Transform3D()

	var rng := RandomNumberGenerator.new()
	rng.seed = ROTATION_SEED

	# Skip RNG calls to reach the correct state for this index
	for i in range(index):
		rng.randf()  # x rotation
		rng.randf()  # y rotation
		rng.randf()  # z rotation

	# Find which layer this index belongs to
	var current_index: int = 0
	var layer: int = 0

	while true:
		var layer_capacity := _get_layer_capacity(layer)
		if current_index + layer_capacity > index:
			# This index is in this layer
			var index_in_layer := index - current_index
			var layer_radius := _get_layer_radius(layer)
			var instances_in_layer := _get_instances_in_layer(layer, total_count, current_index)
			var position := _fibonacci_sphere_point(index_in_layer, instances_in_layer, layer_radius)
			var rotation := _calculate_rotation(position, rng)
			return Transform3D(rotation, position)

		current_index += layer_capacity
		layer += 1

	return Transform3D()


## Returns the radius for the given layer index.
static func _get_layer_radius(layer: int) -> float:
	if layer == 0:
		return BASE_RADIUS
	return BASE_RADIUS + (LAYER_SPACING * BASE_RADIUS * layer)


## Returns the maximum capacity of the given layer.
## Based on sphere surface area to maintain consistent density.
static func _get_layer_capacity(layer: int) -> int:
	var radius := _get_layer_radius(layer)
	var surface_area := 4.0 * PI * radius * radius
	return maxi(1, int(surface_area * DENSITY_FACTOR))


## Returns actual instances in this layer given total count.
static func _get_instances_in_layer(layer: int, total_count: int, layer_start: int) -> int:
	var layer_capacity := _get_layer_capacity(layer)
	return mini(layer_capacity, total_count - layer_start)


## Calculates a point on a Fibonacci sphere.
## Returns evenly distributed points using the golden angle spiral.
static func _fibonacci_sphere_point(index: int, total: int, radius: float) -> Vector3:
	if total <= 1:
		return Vector3.ZERO if total == 0 else Vector3(0, 0, radius)

	# Distribute points from bottom to top of sphere
	var y_normalized: float = 1.0 - (float(index) / float(total - 1)) * 2.0
	var radius_at_y: float = sqrt(1.0 - y_normalized * y_normalized)
	var theta: float = GOLDEN_ANGLE * index

	return Vector3(
		cos(theta) * radius_at_y * radius,
		y_normalized * radius,
		sin(theta) * radius_at_y * radius
	)


## Calculates rotation basis for an instance.
## Orients the lobster to face outward with random variation.
static func _calculate_rotation(position: Vector3, rng: RandomNumberGenerator) -> Basis:
	# Base orientation: face outward from center
	var forward := position.normalized() if position.length_squared() > 0.001 else Vector3.FORWARD
	var up := Vector3.UP

	# Handle edge case where forward is parallel to up
	if absf(forward.dot(up)) > 0.99:
		up = Vector3.RIGHT

	var right := up.cross(forward).normalized()
	up = forward.cross(right).normalized()

	var base_basis := Basis(right, up, forward)

	# Add random rotation offset for visual variety
	var random_rotation := Basis()
	random_rotation = random_rotation.rotated(Vector3.RIGHT, (rng.randf() - 0.5) * MAX_ROTATION_OFFSET)
	random_rotation = random_rotation.rotated(Vector3.UP, (rng.randf() - 0.5) * MAX_ROTATION_OFFSET)
	random_rotation = random_rotation.rotated(Vector3.FORWARD, (rng.randf() - 0.5) * MAX_ROTATION_OFFSET)

	return base_basis * random_rotation


## Returns the number of layers needed for the given count.
static func get_layer_count(count: int) -> int:
	if count <= 0:
		return 0

	var current_index: int = 0
	var layer: int = 0

	while current_index < count:
		current_index += _get_layer_capacity(layer)
		layer += 1

	return layer


## Returns the outer radius of the swarm for the given count.
## Useful for camera positioning.
static func get_swarm_radius(count: int) -> float:
	var layers := get_layer_count(count)
	if layers == 0:
		return 0.0
	return _get_layer_radius(layers - 1)
