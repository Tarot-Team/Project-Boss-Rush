extends RefCounted
class_name AbilityKit

const ICON_COMET := preload("res://fireball_icon.png")
const ICON_MOON_LASER := preload("res://assets/attacks/Light Beam.png")
const ICON_NEPTUNE_SURGE := preload("res://assets/player/neptune/neptune_summons/fire orb.jpg")

## Central place for cooldowns, HUD, display strings, and companion rules. When you add a new ability id:
## 1) Constant in CharacterData
## 2) Cooldown + hud + name here
## 3) If it needs a persistent node, add secondary_requires_* helpers and handle in Player._sync_companion_nodes +
##    try_primary_attack / try_secondary_attack (or small helper methods on Player).


static func default_primary_for_character(character_id: String) -> String:
	match character_id:
		"venus":
			return CharacterData.ABILITY_ARROW_POISON
		"moon":
			return CharacterData.ABILITY_SLASH_LIGHT
		"neptune":
			return CharacterData.ABILITY_SLASH_WATER
		"mercury":
			return CharacterData.ABILITY_SLASH_QUICK
		_:
			return CharacterData.ABILITY_SLASH


static func default_secondary_for_character(character_id: String) -> String:
	match character_id:
		"venus":
			return CharacterData.ABILITY_POISON_FLASK
		"mars":
			return CharacterData.ABILITY_FIRE_SLASH
		"mercury":
			return CharacterData.ABILITY_COMET
		"moon":
			return CharacterData.ABILITY_MOON_LASER
		"neptune":
			return CharacterData.ABILITY_NEPTUNE_SURGE
		_:
			return CharacterData.ABILITY_COMET


static func attack_cooldown(ability_id: String) -> float:
	match ability_id:
		CharacterData.ABILITY_SLASH_QUICK:
			return 0.2
		_:
			return 0.46


static func secondary_cooldown(ability_id: String) -> float:
	match ability_id:
		CharacterData.ABILITY_POISON_FLASK:
			return 1.45
		CharacterData.ABILITY_FIRE_SLASH:
			return 1.75
		CharacterData.ABILITY_COMET:
			return 1.4
		CharacterData.ABILITY_NEPTUNE_SURGE:
			return 2.25
		_:
			return 1.5


static func melee_slash_texture(ability_id: String) -> Texture2D:
	match ability_id:
		CharacterData.ABILITY_SLASH_QUICK:
			return CharacterCombat.load_tex(CharacterCombat.TEX_SLASH)
		CharacterData.ABILITY_SLASH_LIGHT:
			return CharacterCombat.load_tex(CharacterCombat.TEX_LIGHT)
		CharacterData.ABILITY_SLASH_WATER:
			return CharacterCombat.load_tex(CharacterCombat.TEX_WATER)
		CharacterData.ABILITY_SLASH:
			return CharacterCombat.load_tex(CharacterCombat.TEX_SLASH)
		_:
			return CharacterCombat.load_tex(CharacterCombat.TEX_SLASH)


static func melee_slash_animation(ability_id: String) -> StringName:
	match ability_id:
		CharacterData.ABILITY_SLASH_QUICK:
			return &"quick_slash"
		CharacterData.ABILITY_SLASH_LIGHT:
			return &"light_slash"
		CharacterData.ABILITY_SLASH_WATER:
			return &"water_slash"
		CharacterData.ABILITY_FIRE_SLASH:
			return &"fire_slash"
		CharacterData.ABILITY_SLASH:
			return &"slash"
		_:
			return &"slash"


static func secondary_requires_neptune_orb(secondary_id: String) -> bool:
	return secondary_id == CharacterData.ABILITY_NEPTUNE_SURGE


static func normalize_ability_id(raw: Variant) -> String:
	return String(raw).strip_edges()


static func secondary_hud_icon(ability_id: String) -> Texture2D:
	match ability_id:
		CharacterData.ABILITY_POISON_FLASK:
			return CharacterCombat.load_tex(CharacterCombat.TEX_POISON_FLASK)
		CharacterData.ABILITY_FIRE_SLASH:
			return CharacterCombat.load_tex(CharacterCombat.TEX_FIRE)
		CharacterData.ABILITY_COMET:
			return ICON_COMET
		CharacterData.ABILITY_MOON_LASER:
			return ICON_MOON_LASER
		CharacterData.ABILITY_NEPTUNE_SURGE:
			return ICON_NEPTUNE_SURGE
		_:
			return ICON_COMET


static func ability_display_name(ability_id: String) -> String:
	match ability_id:
		CharacterData.ABILITY_SLASH:
			return "Slash"
		CharacterData.ABILITY_SLASH_QUICK:
			return "Quick slash"
		CharacterData.ABILITY_SLASH_LIGHT:
			return "Light slash"
		CharacterData.ABILITY_SLASH_WATER:
			return "Water slash"
		CharacterData.ABILITY_ARROW_POISON:
			return "Poison arrow"
		CharacterData.ABILITY_FIRE_SLASH:
			return "Fire slash"
		CharacterData.ABILITY_COMET:
			return "Silver comet"
		CharacterData.ABILITY_POISON_FLASK:
			return "Poison flask"
		CharacterData.ABILITY_MOON_LASER:
			return "Moon beam"
		CharacterData.ABILITY_NEPTUNE_SURGE:
			return "Summon orb"
		CharacterData.ABILITY_DODGE:
			return "Dodge"
		_:
			return ability_id if ability_id != "" else "—"


static func loadout_summary(player_class: Dictionary) -> String:
	var has_dodge: bool = CharacterData.ABILITY_DODGE in player_class.get("abilities", [])
	var pid: String = String(player_class.get("primary_ability", ""))
	var sid: String = String(player_class.get("secondary_ability", ""))
	var cid: String = String(player_class.get("id", "mars"))
	if pid == "":
		pid = default_primary_for_character(cid)
	if sid == "":
		sid = default_secondary_for_character(cid)
	var dodge_str: String = ability_display_name(CharacterData.ABILITY_DODGE) if has_dodge else "—"
	return "LMB: %s  ·  Shift: %s  ·  RMB: %s" % [
		ability_display_name(pid),
		dodge_str,
		ability_display_name(sid),
	]
