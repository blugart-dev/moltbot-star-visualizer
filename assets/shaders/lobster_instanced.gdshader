shader_type spatial;

// Instanced lobster shader for MultiMesh rendering.
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

// Animation amplitude for idle bobbing (0.0 to disable)
uniform float idle_amplitude : hint_range(0.0, 0.5) = 0.05;

// Animation speed multiplier
uniform float idle_speed : hint_range(0.1, 5.0) = 1.0;

// Roughness for the shell surface
uniform float roughness : hint_range(0.0, 1.0) = 0.7;

// Metallic appearance (lobster shells have slight sheen)
uniform float metallic : hint_range(0.0, 1.0) = 0.1;

// Pass custom data to fragment shader
varying vec4 v_instance_custom;

void vertex() {
	// Read per-instance custom data
	v_instance_custom = INSTANCE_CUSTOM;

	// Animation phase offset from custom data alpha channel
	// Multiply by TAU (2*PI) to get full cycle offset
	float phase = v_instance_custom.a * 6.28318530718; // TAU

	// Idle bobbing animation - subtle vertical movement
	// Each instance has a different phase so they don't move in sync
	if (idle_amplitude > 0.0) {
		float bob = sin(TIME * idle_speed + phase) * idle_amplitude;
		VERTEX.y += bob;
	}
}

void fragment() {
	// Apply per-instance color tint
	// RGB channels of INSTANCE_CUSTOM modify the base color
	vec3 tint = v_instance_custom.rgb;

	// Multiply base color by tint (values around 1.0 preserve color,
	// < 1.0 darkens, > 1.0 brightens)
	ALBEDO = base_color * tint;

	// Surface properties
	ROUGHNESS = roughness;
	METALLIC = metallic;
}
