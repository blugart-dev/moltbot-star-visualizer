class_name PositionCalculator
extends RefCounted
## Calculates 3D positions for lobster instances using Fibonacci sphere distribution.
##
## All instances are distributed evenly on a single sphere that grows with count.
## Uses the golden angle spiral for uniform distribution.

## Golden angle in radians for Fibonacci spiral distribution.
const GOLDEN_ANGLE: float = PI * (3.0 - sqrt(5.0))

## Base radius for small counts.
const BASE_RADIUS: float = 5.0

## Controls how fast radius grows with count.
const RADIUS_SCALE: float = 0.015

## Random seed for deterministic rotations.
const ROTATION_SEED: int = 12345


## Calculates transforms for the specified number of instances.
## Returns deterministic positions distributed on a Fibonacci sphere.
static func calculate_positions(count: int) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	if count <= 0:
		return result

	result.resize(count)

	var radius := get_swarm_radius(count)

	# Use a seeded random number generator for deterministic rotations
	var rng := RandomNumberGenerator.new()
	rng.seed = ROTATION_SEED

	for i in range(count):
		var position := _fibonacci_sphere_point(i, count, radius)
		var rotation := _calculate_rotation(rng)
		result[i] = Transform3D(rotation, position)

	return result


## Calculates a single position for incremental updates.
static func calculate_single_position(index: int, total_count: int) -> Transform3D:
	if index < 0 or index >= total_count:
		return Transform3D()

	var rng := RandomNumberGenerator.new()
	rng.seed = ROTATION_SEED

	# Skip RNG calls to reach the correct state for this index
	for i in range(index * 3):
		rng.randf()

	var radius := get_swarm_radius(total_count)
	var position := _fibonacci_sphere_point(index, total_count, radius)
	var rotation := _calculate_rotation(rng)
	return Transform3D(rotation, position)


## Calculates a point on a Fibonacci sphere.
## Returns evenly distributed points using the golden angle spiral.
static func _fibonacci_sphere_point(index: int, total: int, radius: float) -> Vector3:
	if total <= 0:
		return Vector3.ZERO
	if total == 1:
		return Vector3.ZERO

	# y goes from 1 to -1 (top to bottom)
	var y_normalized: float = 1.0 - (2.0 * index + 1.0) / float(total)
	var radius_at_y: float = sqrt(1.0 - y_normalized * y_normalized)
	var theta: float = GOLDEN_ANGLE * index

	return Vector3(
		cos(theta) * radius_at_y * radius,
		y_normalized * radius,
		sin(theta) * radius_at_y * radius
	)


## Calculates rotation basis for an instance.
## Random orientation for natural swarm look.
static func _calculate_rotation(rng: RandomNumberGenerator) -> Basis:
	# Random rotation on all axes for varied orientations
	var basis := Basis.IDENTITY
	basis = basis.rotated(Vector3.UP, rng.randf() * TAU)
	basis = basis.rotated(Vector3.RIGHT, rng.randf() * TAU * 0.5 - PI * 0.25)
	basis = basis.rotated(Vector3.FORWARD, rng.randf() * TAU * 0.25)
	return basis


## Returns the outer radius of the swarm for the given count.
## Useful for camera positioning.
static func get_swarm_radius(count: int) -> float:
	if count <= 0:
		return 0.0
	# Radius grows with cube root of count to maintain density
	return BASE_RADIUS + RADIUS_SCALE * pow(float(count), 0.5)
