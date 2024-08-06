shader_type canvas_item;

void fragment()
{
	vec2 uv_screen = SCREEN_UV;
	
	COLOR.rgb = textureLod(TEXTURE, uv_screen, 0.0).rgb;
}