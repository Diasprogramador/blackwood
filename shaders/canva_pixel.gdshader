shader_type canvas_item;
render_mode unshaded;
varying vec4 tint;
void vertex() {
	tint = COLOR;
}
void fragment() {
	// Sample in square source-pixel pairs for a crisp, consistent pixel grid.
	vec2 grid = TEXTURE_PIXEL_SIZE * 2.0;
	vec2 uv = (floor(UV / grid) + 0.5) * grid;
	vec4 ink = texture(TEXTURE, uv);
	// Magenta chroma key, preserving violet garments and dark outlines.
	float key = step(0.40, ink.r) * step(0.40, ink.b) * step(ink.g + 0.23, min(ink.r, ink.b));
	if (ink.r > 0.28 && ink.b > 0.28 && min(ink.r, ink.b) > ink.g + 0.16) {
		ink.b = min(ink.b, max(ink.g, ink.r * 0.55));
	}
	COLOR = vec4(ink.rgb, ink.a * (1.0 - key)) * tint;
}
