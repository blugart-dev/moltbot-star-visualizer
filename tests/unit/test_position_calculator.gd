extends GutTest
## Unit tests for PositionCalculator.

const PositionCalculatorScript := preload("res://scripts/core/position_calculator.gd")


func test_empty_count_returns_empty_array() -> void:
	var result := PositionCalculatorScript.calculate_positions(0)
	assert_eq(result.size(), 0, "Should return empty array for count 0")


func test_negative_count_returns_empty_array() -> void:
	var result := PositionCalculatorScript.calculate_positions(-5)
	assert_eq(result.size(), 0, "Should return empty array for negative count")


func test_single_instance_at_origin() -> void:
	var result := PositionCalculatorScript.calculate_positions(1)
	assert_eq(result.size(), 1, "Should return 1 transform")
	# Single instance is at origin
	assert_eq(result[0].origin, Vector3.ZERO, "Single instance should be at origin")


func test_returns_correct_count() -> void:
	for count in [1, 10, 100, 1000]:
		var result := PositionCalculatorScript.calculate_positions(count)
		assert_eq(result.size(), count, "Should return %d transforms" % count)


func test_positions_are_deterministic() -> void:
	var result1 := PositionCalculatorScript.calculate_positions(50)
	var result2 := PositionCalculatorScript.calculate_positions(50)

	for i in range(50):
		assert_eq(result1[i].origin, result2[i].origin,
			"Position %d should be identical across calls" % i)
		assert_eq(result1[i].basis, result2[i].basis,
			"Rotation %d should be identical across calls" % i)


func test_no_duplicate_positions() -> void:
	var result := PositionCalculatorScript.calculate_positions(100)
	var positions: Array[Vector3] = []

	for xform in result:
		positions.append(xform.origin)

	# Check for duplicates with small tolerance
	for i in range(positions.size()):
		for j in range(i + 1, positions.size()):
			var distance := positions[i].distance_to(positions[j])
			assert_gt(distance, 0.01,
				"Positions %d and %d should not overlap (distance: %f)" % [i, j, distance])


func test_positions_distributed_around_origin() -> void:
	var result := PositionCalculatorScript.calculate_positions(100)

	# Calculate center of mass - should be near origin
	var center := Vector3.ZERO
	for xform in result:
		center += xform.origin
	center /= result.size()

	# Center of mass should be near origin (within reasonable tolerance)
	assert_lt(center.length(), 2.0,
		"Center of mass should be near origin, got %s" % str(center))


func test_distribution_not_grid_like() -> void:
	var result := PositionCalculatorScript.calculate_positions(100)

	# Check that positions aren't axis-aligned (would indicate grid)
	var axis_aligned_count: int = 0
	for xform in result:
		var pos := xform.origin
		# Check if position is axis-aligned (two components near zero)
		var near_zero_count: int = 0
		if absf(pos.x) < 0.1:
			near_zero_count += 1
		if absf(pos.y) < 0.1:
			near_zero_count += 1
		if absf(pos.z) < 0.1:
			near_zero_count += 1
		if near_zero_count >= 2:
			axis_aligned_count += 1

	# Allow some axis-aligned positions, but not too many
	assert_lt(axis_aligned_count, 10,
		"Too many axis-aligned positions (%d), distribution may be grid-like" % axis_aligned_count)


func test_includes_rotation_variety() -> void:
	var result := PositionCalculatorScript.calculate_positions(50)

	# Check that rotations vary (not all identical)
	var unique_rotations: int = 0
	var first_basis := result[0].basis

	for xform in result:
		if not xform.basis.is_equal_approx(first_basis):
			unique_rotations += 1

	assert_gt(unique_rotations, 40,
		"Should have rotation variety, found only %d unique rotations" % unique_rotations)


func test_rotations_are_varied() -> void:
	var result := PositionCalculatorScript.calculate_positions(20)

	# Rotations are random for natural swarm look - just verify they exist
	var has_varied_rotation: bool = false
	var first_basis := result[0].basis

	for i in range(1, result.size()):
		if not result[i].basis.is_equal_approx(first_basis):
			has_varied_rotation = true
			break

	assert_true(has_varied_rotation, "Rotations should vary across instances")


func test_handles_large_counts_efficiently() -> void:
	var start_time := Time.get_ticks_msec()
	var result := PositionCalculatorScript.calculate_positions(10000)
	var elapsed := Time.get_ticks_msec() - start_time

	assert_eq(result.size(), 10000, "Should handle 10000 instances")
	# Should complete in under 1 second (usually much faster)
	assert_lt(elapsed, 1000, "Should calculate 10000 positions quickly (took %dms)" % elapsed)


func test_handles_100k_instances() -> void:
	var start_time := Time.get_ticks_msec()
	var result := PositionCalculatorScript.calculate_positions(100000)
	var elapsed := Time.get_ticks_msec() - start_time

	assert_eq(result.size(), 100000, "Should handle 100000 instances")
	# Should complete in under 5 seconds
	assert_lt(elapsed, 5000, "Should calculate 100000 positions reasonably fast (took %dms)" % elapsed)


func test_swarm_grows_with_count() -> void:
	var radius_10 := PositionCalculatorScript.get_swarm_radius(10)
	var radius_100 := PositionCalculatorScript.get_swarm_radius(100)
	var radius_1000 := PositionCalculatorScript.get_swarm_radius(1000)

	assert_gt(radius_100, radius_10, "Larger count should have larger radius")
	assert_gt(radius_1000, radius_100, "Even larger count should have even larger radius")


func test_calculate_single_position_matches_batch() -> void:
	var count: int = 50
	var batch_result := PositionCalculatorScript.calculate_positions(count)

	# Test a few individual positions
	for i in [0, 10, 25, 49]:
		var single := PositionCalculatorScript.calculate_single_position(i, count)
		assert_eq(single.origin, batch_result[i].origin,
			"Single position %d should match batch" % i)
		assert_true(single.basis.is_equal_approx(batch_result[i].basis),
			"Single rotation %d should match batch" % i)


func test_calculate_single_position_out_of_range() -> void:
	var result := PositionCalculatorScript.calculate_single_position(-1, 10)
	assert_eq(result, Transform3D(), "Negative index should return identity transform")

	result = PositionCalculatorScript.calculate_single_position(10, 10)
	assert_eq(result, Transform3D(), "Index >= count should return identity transform")


func test_zero_swarm_radius() -> void:
	assert_eq(PositionCalculatorScript.get_swarm_radius(0), 0.0,
		"Zero count should have zero radius")


func test_positions_spread_across_sphere() -> void:
	var result := PositionCalculatorScript.calculate_positions(100)

	# Count positions in each octant of 3D space
	var octant_counts: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]

	for xform in result:
		var pos := xform.origin
		var octant: int = 0
		if pos.x >= 0:
			octant += 1
		if pos.y >= 0:
			octant += 2
		if pos.z >= 0:
			octant += 4
		octant_counts[octant] += 1

	# Each octant should have some positions (allow for some variance)
	for i in range(8):
		assert_gt(octant_counts[i], 5,
			"Octant %d should have some positions, got %d" % [i, octant_counts[i]])
