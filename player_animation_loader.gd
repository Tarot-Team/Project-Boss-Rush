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

	# Moon: attack combo from moon_attacks
	if character_id == "moon":
		var atk: Array[Texture2D] = _load_textures_from_folder("res://assets/player/moon/moon_attacks")
		if not atk.is_empty():
			frames.add_animation(&"attack")
			for t2 in atk:
				frames.add_frame(&"attack", t2, 1.0, -1)
			frames.set_animation_loop(&"attack", false)
			frames.set_animation_speed(&"attack", 18.0)

	return frames
