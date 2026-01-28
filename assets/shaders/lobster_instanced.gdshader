shader_type spatial;
render_mode unshaded;

// Instanced lobster shader for MultiMesh rendering (UNLIT).
//
// Uses INSTANCE_CUSTOM data from MultiMesh.set_instance_custom_data() for
// per-instance variation to prevent the "clone army" look.
//
// Custom Data Encoding:
//   Color.r: Red tint multiplier (typically 0.8 - 1.2)
//   Color.g: Green tint multiplier (typically 0.8 - 1.2)
//   Color.b: Blue tint multiplier (typically 0.8 - 1.2)
//   Color.a: Animation phase offset (0.0 - 1.0, multiplied by TAU for full cycle)
//
// WebGL 2.0 compatible (GL Compatibility renderer).

// Base lobster color - reddish-orange
uniform vec3 base_color : source_color = vec3(0.8, 0.25, 0.15);

// Darker color for shell segments
uniform vec3 segment_color : source_color = vec3(0.5, 0.15, 0.08);

// Animation amplitude for idle bobbing (0.0 to disable)
uniform float idle_amplitude : hint_range(0.0, 0.5) = 0.08;

// Animation speed multiplier
uniform float idle_speed : hint_range(0.1, 5.0) = 0.8;

// Sway rotation amplitude in radians
uniform float sway_amplitude : hint_range(0.0, 0.3) = 0.1;

// Pass custom data and local position to fragment shader
varying vec4 v_instance_custom;
varying vec3 v_local_pos;
varying vec3 v_local_normal;

void vertex() {
	// Read per-instance custom data
	v_instance_custom = INSTANCE_CUSTOM;
	v_local_pos = VERTEX;
	v_local_normal = NORMAL;

	// Animation phase offset from custom data alpha channel
	float phase = v_instance_custom.a * 6.28318530718; // TAU

	// Idle bobbing animation - subtle vertical movement
	if (idle_amplitude > 0.0) {
		float bob = sin(TIME * idle_speed + phase) * idle_amplitude;
		VERTEX.y += bob;
	}

	// Gentle sway rotation around Y axis
	if (sway_amplitude > 0.0) {
		float sway_angle = sin(TIME * idle_speed * 0.7 + phase * 1.3) * sway_amplitude;
		float cos_a = cos(sway_angle);
		float sin_a = sin(sway_angle);
		vec3 swayed = VERTEX;
		swayed.x = VERTEX.x * cos_a - VERTEX.z * sin_a;
		swayed.z = VERTEX.x * sin_a + VERTEX.z * cos_a;
		VERTEX = swayed;
	}
}

void fragment() {
	// Apply per-instance color tint
	vec3 tint = v_instance_custom.rgb;
	vec3 color = base_color * tint;

	// Shell segment bands based on local Z position (along body length)
	float segment_freq = 12.0;
	float segment_pattern = sin(v_local_pos.z * segment_freq) * 0.5 + 0.5;
	segment_pattern = smoothstep(0.3, 0.7, segment_pattern);

	// Add darker segment lines
	color = mix(color, segment_color * tint, segment_pattern * 0.4);

	// Lighter belly (bottom facing normals)
	float belly = max(0.0, -v_local_normal.y);
	color = mix(color, color * 1.3, belly * 0.3);

	// Rim highlight for depth (edges facing away from camera)
	float rim = 1.0 - abs(dot(normalize(v_local_normal), vec3(0.0, 0.0, 1.0)));
	rim = pow(rim, 2.0);
	color = mix(color, color * 1.2, rim * 0.2);

	ALBEDO = color;
}
