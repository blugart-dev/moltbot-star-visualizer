class_name LobsterMeshGenerator
extends RefCounted
## Generates a low-poly lobster mesh procedurally using SurfaceTool.
##
## Creates a stylized lobster with body, tail, claws, legs, and antennae.
## Target: ~340 triangles for web performance.


## Creates the complete lobster mesh with material applied.
static func create_lobster_mesh() -> ArrayMesh:
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Build all lobster parts
	_add_body(surface_tool)
	_add_tail(surface_tool)
	_add_claws(surface_tool)
	_add_legs(surface_tool)
	_add_antennae(surface_tool)

	# Generate normals for proper lighting
	surface_tool.generate_normals()

	var mesh := surface_tool.commit()

	# Apply the instanced shader material
	var material: ShaderMaterial = load("res://assets/materials/lobster_material.tres")
	if material:
		mesh.surface_set_material(0, material)

	return mesh


## Body: Elongated ellipsoid shape
static func _add_body(st: SurfaceTool) -> void:
	var segments := 8
	var rings := 5
	var radius_x := 0.15
	var radius_y := 0.12
	var radius_z := 0.35
	var center := Vector3(0, 0, 0)

	_add_ellipsoid(st, center, radius_x, radius_y, radius_z, segments, rings)


## Tail: Series of segmented plates fanning out
static func _add_tail(st: SurfaceTool) -> void:
	var tail_start := Vector3(0, 0, 0.35)
	var segment_length := 0.12
	var start_width := 0.12
	var start_height := 0.08

	# 5 tail segments, each slightly smaller
	for i in range(5):
		var t := float(i) / 4.0
		var width := start_width * (1.0 - t * 0.5)
		var height := start_height * (1.0 - t * 0.6)
		var z_start := tail_start.z + i * segment_length
		var z_end := z_start + segment_length * 0.9

		_add_box(st, Vector3(0, 0, (z_start + z_end) / 2.0),
				Vector3(width, height, segment_length * 0.85))

	# Tail fan at the end
	var fan_z := tail_start.z + 5 * segment_length
	_add_tail_fan(st, Vector3(0, 0, fan_z))


## Tail fan: Flat triangular plates
static func _add_tail_fan(st: SurfaceTool, position: Vector3) -> void:
	var fan_length := 0.15
	var fan_width := 0.18

	# Central plate
	_add_flat_plate(st, position, fan_length, fan_width * 0.4, 0.0)

	# Side plates angled outward
	_add_flat_plate(st, position + Vector3(0.06, 0, 0), fan_length * 0.9, fan_width * 0.3, 20.0)
	_add_flat_plate(st, position + Vector3(-0.06, 0, 0), fan_length * 0.9, fan_width * 0.3, -20.0)


## Claws: Simplified wedge/pincer shapes
static func _add_claws(st: SurfaceTool) -> void:
	# Right claw (larger)
	_add_claw(st, Vector3(0.2, 0, -0.25), 1.0, false)
	# Left claw (slightly smaller)
	_add_claw(st, Vector3(-0.2, 0, -0.25), 0.85, true)


static func _add_claw(st: SurfaceTool, base: Vector3, size_mult: float, mirror: bool) -> void:
	var arm_length := 0.15 * size_mult
	var claw_length := 0.12 * size_mult
	var claw_width := 0.06 * size_mult

	var mirror_x := -1.0 if mirror else 1.0

	# Arm segment
	var arm_end := base + Vector3(0.1 * mirror_x, 0, -arm_length)
	_add_tapered_cylinder(st, base, arm_end, 0.03 * size_mult, 0.025 * size_mult, 5)

	# Claw body (wider part)
	var claw_base := arm_end
	var claw_end := claw_base + Vector3(0.05 * mirror_x, 0, -claw_length)
	_add_tapered_cylinder(st, claw_base, claw_end, 0.025 * size_mult, 0.04 * size_mult, 5)

	# Upper pincer
	var pincer_top := claw_end + Vector3(0, 0.015, -0.06 * size_mult)
	_add_tapered_cylinder(st, claw_end + Vector3(0, 0.01, 0), pincer_top, 0.02 * size_mult, 0.008 * size_mult, 4)

	# Lower pincer
	var pincer_bottom := claw_end + Vector3(0, -0.015, -0.05 * size_mult)
	_add_tapered_cylinder(st, claw_end + Vector3(0, -0.01, 0), pincer_bottom, 0.015 * size_mult, 0.006 * size_mult, 4)


## Legs: 6 pairs of simple jointed legs
static func _add_legs(st: SurfaceTool) -> void:
	var leg_positions := [
		Vector3(0.12, -0.05, 0.1),
		Vector3(0.12, -0.05, 0.0),
		Vector3(0.12, -0.05, -0.1),
	]

	for pos in leg_positions:
		_add_leg(st, pos, false)
		_add_leg(st, Vector3(-pos.x, pos.y, pos.z), true)


static func _add_leg(st: SurfaceTool, base: Vector3, mirror: bool) -> void:
	var mirror_x := -1.0 if mirror else 1.0
	var upper_length := 0.08
	var lower_length := 0.1
	var thickness := 0.012

	# Upper leg segment (angled outward and down)
	var joint := base + Vector3(0.06 * mirror_x, -0.04, 0)
	_add_tapered_cylinder(st, base, joint, thickness, thickness * 0.8, 4)

	# Lower leg segment (angled down)
	var foot := joint + Vector3(0.02 * mirror_x, -0.08, 0.02)
	_add_tapered_cylinder(st, joint, foot, thickness * 0.8, thickness * 0.4, 4)


## Antennae: Two long thin feelers
static func _add_antennae(st: SurfaceTool) -> void:
	var base_right := Vector3(0.05, 0.05, -0.35)
	var base_left := Vector3(-0.05, 0.05, -0.35)
	var length := 0.4

	# Right antenna - curves outward
	var tip_right := base_right + Vector3(0.15, 0.1, -length)
	_add_tapered_cylinder(st, base_right, tip_right, 0.01, 0.003, 4)

	# Left antenna - curves outward
	var tip_left := base_left + Vector3(-0.15, 0.1, -length)
	_add_tapered_cylinder(st, base_left, tip_left, 0.01, 0.003, 4)


# === Primitive Helpers ===

## Adds an ellipsoid centered at the given position
static func _add_ellipsoid(st: SurfaceTool, center: Vector3, rx: float, ry: float, rz: float,
		segments: int, rings: int) -> void:
	for i in range(rings):
		var theta1 := PI * float(i) / float(rings)
		var theta2 := PI * float(i + 1) / float(rings)

		for j in range(segments):
			var phi1 := TAU * float(j) / float(segments)
			var phi2 := TAU * float(j + 1) / float(segments)

			# Four corners of the quad
			var p1 := center + _ellipsoid_point(rx, ry, rz, theta1, phi1)
			var p2 := center + _ellipsoid_point(rx, ry, rz, theta1, phi2)
			var p3 := center + _ellipsoid_point(rx, ry, rz, theta2, phi2)
			var p4 := center + _ellipsoid_point(rx, ry, rz, theta2, phi1)

			# Two triangles per quad
			st.add_vertex(p1)
			st.add_vertex(p2)
			st.add_vertex(p3)

			st.add_vertex(p1)
			st.add_vertex(p3)
			st.add_vertex(p4)


static func _ellipsoid_point(rx: float, ry: float, rz: float, theta: float, phi: float) -> Vector3:
	return Vector3(
		rx * sin(theta) * cos(phi),
		ry * cos(theta),
		rz * sin(theta) * sin(phi)
	)


## Adds a box centered at the given position
static func _add_box(st: SurfaceTool, center: Vector3, size: Vector3) -> void:
	var hx := size.x / 2.0
	var hy := size.y / 2.0
	var hz := size.z / 2.0

	# Define 8 corners
	var corners := [
		center + Vector3(-hx, -hy, -hz),  # 0
		center + Vector3( hx, -hy, -hz),  # 1
		center + Vector3( hx,  hy, -hz),  # 2
		center + Vector3(-hx,  hy, -hz),  # 3
		center + Vector3(-hx, -hy,  hz),  # 4
		center + Vector3( hx, -hy,  hz),  # 5
		center + Vector3( hx,  hy,  hz),  # 6
		center + Vector3(-hx,  hy,  hz),  # 7
	]

	# 6 faces, 2 triangles each
	var faces := [
		[0, 1, 2, 3],  # Front
		[5, 4, 7, 6],  # Back
		[4, 0, 3, 7],  # Left
		[1, 5, 6, 2],  # Right
		[3, 2, 6, 7],  # Top
		[4, 5, 1, 0],  # Bottom
	]

	for face in faces:
		st.add_vertex(corners[face[0]])
		st.add_vertex(corners[face[1]])
		st.add_vertex(corners[face[2]])

		st.add_vertex(corners[face[0]])
		st.add_vertex(corners[face[2]])
		st.add_vertex(corners[face[3]])


## Adds a flat plate (thin box) with optional Y rotation
static func _add_flat_plate(st: SurfaceTool, center: Vector3, length: float, width: float,
		angle_deg: float) -> void:
	var thickness := 0.01
	var angle := deg_to_rad(angle_deg)

	# Rotate corners around Y axis
	var cos_a := cos(angle)
	var sin_a := sin(angle)

	var hw := width / 2.0
	var hl := length
	var ht := thickness / 2.0

	# Local corners before rotation
	var local_corners := [
		Vector3(-hw, -ht, 0),
		Vector3( hw, -ht, 0),
		Vector3( hw, -ht, hl),
		Vector3(-hw, -ht, hl),
		Vector3(-hw,  ht, 0),
		Vector3( hw,  ht, 0),
		Vector3( hw,  ht, hl),
		Vector3(-hw,  ht, hl),
	]

	# Rotate and translate
	var corners: Array[Vector3] = []
	for lc in local_corners:
		var rotated := Vector3(
			lc.x * cos_a - lc.z * sin_a,
			lc.y,
			lc.x * sin_a + lc.z * cos_a
		)
		corners.append(center + rotated)

	# Add faces (top and bottom mainly visible)
	# Top face
	st.add_vertex(corners[4])
	st.add_vertex(corners[5])
	st.add_vertex(corners[6])
	st.add_vertex(corners[4])
	st.add_vertex(corners[6])
	st.add_vertex(corners[7])

	# Bottom face
	st.add_vertex(corners[0])
	st.add_vertex(corners[3])
	st.add_vertex(corners[2])
	st.add_vertex(corners[0])
	st.add_vertex(corners[2])
	st.add_vertex(corners[1])


## Adds a tapered cylinder between two points
static func _add_tapered_cylinder(st: SurfaceTool, start: Vector3, end: Vector3,
		radius_start: float, radius_end: float, segments: int) -> void:
	var direction := (end - start).normalized()
	var length := start.distance_to(end)

	# Create perpendicular vectors for the circle
	var up := Vector3.UP
	if abs(direction.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var right := direction.cross(up).normalized()
	up = right.cross(direction).normalized()

	# Generate vertices around both circles
	var start_verts: Array[Vector3] = []
	var end_verts: Array[Vector3] = []

	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		var offset := right * cos(angle) + up * sin(angle)
		start_verts.append(start + offset * radius_start)
		end_verts.append(end + offset * radius_end)

	# Create triangles for the side
	for i in range(segments):
		var next := (i + 1) % segments

		# Two triangles per segment
		st.add_vertex(start_verts[i])
		st.add_vertex(end_verts[i])
		st.add_vertex(end_verts[next])

		st.add_vertex(start_verts[i])
		st.add_vertex(end_verts[next])
		st.add_vertex(start_verts[next])

	# Cap the start
	for i in range(1, segments - 1):
		st.add_vertex(start_verts[0])
		st.add_vertex(start_verts[i + 1])
		st.add_vertex(start_verts[i])

	# Cap the end
	for i in range(1, segments - 1):
		st.add_vertex(end_verts[0])
		st.add_vertex(end_verts[i])
		st.add_vertex(end_verts[i + 1])
