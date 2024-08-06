shader_type sky;

uniform vec3 color : source_color = vec3(0.3,0.3,0.33);
uniform sampler2D noise;

void sky() {
	vec2 pos = vec2(SKY_COORDS.x,SKY_COORDS.y)*10.0;
	float noise_value = 0.02*(texture(noise,pos).r-0.5);
	float blend = abs(2.0*SKY_COORDS.y-1.0);
	
	COLOR = 0.5*color + mix(noise_value, 0.0, blend);
}
