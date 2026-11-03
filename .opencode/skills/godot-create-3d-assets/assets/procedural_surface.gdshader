shader_type spatial;

uniform vec3 dark_color : source_color = vec3(0.12, 0.055, 0.02);
uniform vec3 light_color : source_color = vec3(0.34, 0.19, 0.07);
uniform float world_scale = 3.0;

varying vec3 world_position;


float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
	float coarse = hash31(floor(world_position * world_scale));
	float fine = hash31(floor(world_position * world_scale * 5.0));
	float value = 0.28 + coarse * 0.54 + fine * 0.12;
	ALBEDO = mix(dark_color, light_color, value);
	ROUGHNESS = 0.94;
	SPECULAR = 0.10;
}
