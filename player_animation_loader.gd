class_name PlayerAnimationLoader
extends RefCounted

static func _load_textures_from_folder(folder: String) -> Array[Texture2D]:
	var png_paths: Array[String] = []
	var dir := DirAccess.open(folder)
	if dir == null:
		push_warning("PlayerAnimationLoader: cannot open folder: ", folder)
		return []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".png") and not fname.begins_with("."):
			png_paths.append(folder.path_join(fname))
		fname = dir.get_next()
	dir.list_dir_end()
	png_paths.sort_custom(func(a, b): return a.get_file().naturalnocasecmp_to(b.get_file()) < 0)
	var textures: Array[Texture2D] = []
	for full in png_paths:
		if ResourceLoader.exists(full):
			var t: Texture2D = load(full)
			if t and t.get_width() > 4:
				textures.append(t)
	return textures


static func _moon_attack_filename_order() -> PackedStringArray:
	return PackedStringArray([
		"moon attack 1.png",
		"moon attack 2.png",
		"moon attack 3.png",
		"moon attack 4.png",
		"moon attack 5.png",
		"moon attack 6.png",
		"moon attack 7.png",
		"moon attack 7.1.png",
		"moon attack 7.2.png",
		"moon attack 7.3.png",
		"moon attack 8.png",
		"moon attack 9.png",
		"moon attack 10.png",
		"moon attack 11.png",
		"moon attack 12.png",
		"moon attack 13.png",
		"moon attack 14.png",
	])


static func _load_moon_attacks_ordered() -> Array[Texture2D]:
	var folder := "res://assets/player/moon/moon_attacks/"
	var out: Array[Texture2D] = []
	for fname: String in _moon_attack_filename_order():
		var p: String = folder.path_join(fname)
		if ResourceLoader.exists(p):
			var t_loaded: Variant = load(p)
			var t_tex: Texture2D = t_loaded as Texture2D
			if t_tex != null and t_tex.get_width() > 4:
				out.append(t_tex)
		else:
			push_warning("PlayerAnimationLoader: missing Moon attack frame: ", p)
	return out


static func _moon_laser_recovery_start(texs: Array[Texture2D]) -> int:
	for i in range(texs.size()):
		var f: String = texs[i].resource_path.get_file()
		if f == "moon attack 10.png":
			return i
	return texs.size()


static func build_sprite_frames_for_character(character_id: String) -> SpriteFrames:
	var walk_folder := ""
	match character_id:
		"mars":
			walk_folder = "res://assets/player/Mars/mars_walk"
		"mercury":
			walk_folder = "res://assets/player/Mercury/Walk"
		"moon":
			walk_folder = "res://assets/player/moon/moon_walk"
		"neptune":
			walk_folder = "res://assets/player/neptune/neptune_walk"
		"venus":
			walk_folder = "res://assets/player/venus"
		_:
			return null

	var textures: Array[Texture2D] = _load_textures_from_folder(walk_folder)
	if textures.is_empty():
		push_warning("PlayerAnimationLoader: no textures in ", walk_folder)
		return null

	var frames := SpriteFrames.new()
	frames.add_animation(&"run")
	for tex in textures:
		frames.add_frame(&"run", tex, 1.0, -1)
	frames.set_animation_loop(&"run", true)

	frames.add_animation(&"idle")
	frames.add_frame(&"idle", textures[0], 1.0, -1)
	frames.set_animation_loop(&"idle", true)

	frames.set_animation_speed(&"run", 10.0)
	frames.set_animation_speed(&"idle", 4.0)

	# Moon: melee uses full combo; beam uses animations split at `moon attack 10.png`.
	if character_id == "moon":
		var atk_ordered: Array[Texture2D] = _load_moon_attacks_ordered()
		if not atk_ordered.is_empty():
			frames.add_animation(&"attack")
			for tex_atk: Texture2D in atk_ordered:
				frames.add_frame(&"attack", tex_atk, 1.0, -1)
			frames.set_animation_loop(&"attack", false)
			frames.set_animation_speed(&"attack", 18.0)

			var split_idx: int = _moon_laser_recovery_start(atk_ordered)
			var windup: Array = atk_ordered.slice(0, split_idx)
			var recovery_tex: Array = atk_ordered.slice(split_idx, atk_ordered.size())

			if windup.size() > 0:
				frames.add_animation(&"moon_laser_charge")
				for tw: Variant in windup:
					var t_wind: Texture2D = tw as Texture2D
					frames.add_frame(&"moon_laser_charge", t_wind, 1.0, -1)
				frames.set_animation_loop(&"moon_laser_charge", false)
				frames.set_animation_speed(&"moon_laser_charge", 18.0)

			if recovery_tex.size() > 0:
				frames.add_animation(&"moon_laser_recovery")
				for tr: Variant in recovery_tex:
					var t_rec: Texture2D = tr as Texture2D
					frames.add_frame(&"moon_laser_recovery", t_rec, 1.0, -1)
				frames.set_animation_loop(&"moon_laser_recovery", false)
				frames.set_animation_speed(&"moon_laser_recovery", 14.0)

	return frames
