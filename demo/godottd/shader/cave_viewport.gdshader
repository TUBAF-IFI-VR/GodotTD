shader_type canvas_item;

uniform mat4 Hx;
uniform mat4 Hy;
uniform mat3 F;
uniform vec2 offset;
uniform vec2 scale;
uniform vec2 resolution = vec2(1920.0, 1080.0);
uniform sampler2D alphamask : hint_default_white;
uniform float alphamask_hide = 0.0;

void fragment()
{
	vec2 uv_screen = SCREEN_UV;
	vec2 uv = uv_screen;
	vec2 uv_alpha = uv_screen;

	uv.x *= resolution.x;
	uv.y = uv.y * resolution.y;

	vec3 p = vec3(0.0, 0.0, 1.0);
	p.x = Hx[0][0] + Hx[0][1]*uv.x + Hx[0][2]*uv.y + Hx[1][0]*uv.x*uv.y
		+ Hx[1][1]*uv.x*uv.x + Hx[1][2]*uv.y*uv.y
		+ Hx[2][0]*uv.x*uv.x*uv.y + Hx[2][1]*uv.x*uv.y*uv.y
		+ Hx[2][2]*uv.x*uv.x*uv.x + Hx[3][0]*uv.y*uv.y*uv.y;
	p.y = Hy[0][0] + Hy[0][1]*uv.x + Hy[0][2]*uv.y + Hy[1][0]*uv.x*uv.y
		+ Hy[1][1]*uv.x*uv.x + Hy[1][2]*uv.y*uv.y
		+ Hy[2][0]*uv.x*uv.x*uv.y + Hy[2][1]*uv.x*uv.y*uv.y
		+ Hy[2][2]*uv.x*uv.x*uv.x + Hy[3][0]*uv.y*uv.y*uv.y;
	p = p*F;
	p /= p.z;

	p.x = p.x - offset.x;
	p.y = p.y - offset.y;
	p.x = p.x/scale.x;
	p.y = p.y/scale.y;

	vec3 col = textureLod(TEXTURE, p.xy, 0.0).rgb;
	float alpha = textureLod(alphamask, uv_alpha, 0.0).a;
	
	COLOR.rgb = col * max(alpha,alphamask_hide);
}