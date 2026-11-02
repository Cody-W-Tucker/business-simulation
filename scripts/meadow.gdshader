shader_type spatial;

uniform sampler2D meadow : source_color, filter_linear_mipmap_anisotropic, repeat_enable;

void fragment() {
	// Crossfade rotated samples over broad patches to break up obvious tiling.
	vec2 p = UV * 150.0;
	float variation = sin(p.x * 0.071 + sin(p.y * 0.035)) * cos(p.y * 0.053 - p.x * 0.018);
	float blend = smoothstep(-0.65, 0.65, variation);
	vec3 grass = texture(meadow, p / 1.4).rgb;
	vec3 other = texture(meadow, vec2(-p.y, p.x) / 1.4 + vec2(0.37, 0.61)).rgb;
	ALBEDO = mix(grass, other, 0.15 + 0.70 * blend);
	ROUGHNESS = 1.0;
}
