extends RefCounted
class_name AmbientGlow
## Soft additive radial pool (shader); reads like a faint lamp — not chunky GradientTexture2D quads.

const _POOL_SHADER := preload("res://ambient_light_pool.gdshader")

static func _white_tex() -> ImageTexture:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	return ImageTexture.create_from_image(img)


static func radial_pool(
		local_pos: Vector2,
		tint: Color,
		strength: float,
		diameter_scale: float,
		falloff_power: float,
		z_idx: int = -10
) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.texture = _white_tex()
	spr.centered = true
	spr.position = local_pos
	spr.scale = Vector2(diameter_scale, diameter_scale)
	spr.z_index = z_idx
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	var mat := ShaderMaterial.new()
	mat.shader = _POOL_SHADER
	mat.set_shader_parameter("light_tint", Vector3(tint.r, tint.g, tint.b))
	mat.set_shader_parameter("strength", strength)
	mat.set_shader_parameter("falloff_power", falloff_power)
	spr.material = mat
	return spr


static func player_aura() -> Sprite2D:
	return radial_pool(
			Vector2(0.0, -72.0),
			Color(1.0, 0.93, 0.78),
			0.1,
			36.0,
			2.35,
			-10
	)


static func enemy_aura() -> Sprite2D:
	return radial_pool(
			Vector2(0.0, -8.0),
			Color(0.72, 0.68, 0.88),
			0.038,
			14.0,
			2.5,
			-10
	)
