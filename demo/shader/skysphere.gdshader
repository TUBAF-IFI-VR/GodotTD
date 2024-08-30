shader_type spatial;
render_mode unshaded;

uniform vec3 color_sky : source_color = vec3(0.3, 0.4, 0.6);
uniform vec3 color_horizon : source_color = vec3(0.46, 0.52, 0.6);

uniform sampler2D noise_color : hint_default_black;
uniform sampler2D noise_cloud : hint_default_black;

void fragment() {
	vec3 color_upper = mix(color_sky, color_horizon, min(pow(UV.y*2.0, 16.0), 1.0) );
	
    vec2 uv_flat = vec2( sin(UV.x*2.0*PI), cos(UV.x*2.0*PI) ) * UV.y;
	
	float noise = texture(noise_color, uv_flat).r;
	noise = smoothstep(0.3, 1.0, 1.0-UV.y) * noise;
	noise = noise*0.2 + 0.8;
	
	float clouds = texture(noise_cloud, uv_flat).r;
	clouds = smoothstep(0.54, 1.0, 1.0-UV.y) * clouds;
	
	color_upper *= noise;
	
	ALBEDO = mix(color_upper, vec3(0.65), clouds);
}