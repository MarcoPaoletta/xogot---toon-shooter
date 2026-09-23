extends RefCounted
## Textures drawn in code (GDD 14): the muzzle flash star.

static var _star: ImageTexture


static func star() -> ImageTexture:
	if _star:
		return _star
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size, size) * 0.5
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5) - c
			var r := p.length() / (size * 0.5)
			var a := atan2(p.y, p.x)
			# eight pointed star: the radius of the edge swings between 0.35 and 1.0
			var edge := 0.35 + 0.65 * pow(abs(cos(a * 4.0)), 6.0)
			var v: float = clamp((edge - r) / 0.12, 0.0, 1.0)
			var core: float = clamp(1.0 - r / 0.35, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 0.95 + 0.05 * core, 0.7 + 0.3 * core, max(v, core)))
	_star = ImageTexture.create_from_image(img)
	return _star
