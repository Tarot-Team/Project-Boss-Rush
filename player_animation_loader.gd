extends RefCounted
class_name PlayerAnimationLoader

const CHARACTER_FRAMES := {
	"mars": preload("res://assets/player/Mars/mars_sprite_frames.tres"),
	"mercury": preload("res://assets/player/Mercury/mercury_sprite_frames.tres"),
	"moon": preload("res://assets/player/moon/moon_sprite_frames.tres"),
	"neptune": preload("res://assets/player/neptune/neptune_sprite_frames.tres"),
	"venus": preload("res://assets/player/venus/venus_sprite_frames.tres"),
}


static func build_sprite_frames_for_character(character_id: String) -> SpriteFrames:
	var frames: SpriteFrames = null
	if CHARACTER_FRAMES.has(character_id):
		frames = CHARACTER_FRAMES[character_id]
	if frames == null:
		push_warning("PlayerAnimationLoader: no SpriteFrames resource for '%s'." % character_id)
	return frames
