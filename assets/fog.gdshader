shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D mask : filter_linear;

void fragment() {
	float revealed = texture(mask, UV).r;
	ALBEDO = vec3(0.02, 0.03, 0.05);
	ALPHA = (1.0 - revealed) * 0.97;
}
