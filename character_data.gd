class_name CharacterData
extends RefCounted

## Stat ranges for ★ ratings on the class picker screen.
## Ability IDs: set `primary_ability`, `secondary_ability`, and optional `abilities` (e.g. dodge)
## on each character dict in `main_menu.gd`. Add the same ID to `AbilityKit` (cooldowns, HUD icon, name)
## and handle it in `player1.gd` `try_primary_attack` / `try_secondary_attack` if it needs custom logic.
## On `Player1`, world companions live under `CompanionAnchor` (top_level @ z_index 6) so they are not
## squashed by `Player1.scale`. Add a matching `AbilityKit.secondary_*` helper when a new kit needs that.
const SPEED_STAT_MIN := 150
const SPEED_STAT_MAX := 350
const LUNGE_STAT_MIN := 50
const LUNGE_STAT_MAX := 500

const ABILITY_DODGE := "dodge"

## Primary (LMB) — assign in main menu `primary_ability` or use `Global` fallbacks.
const ABILITY_SLASH := "slash"
const ABILITY_SLASH_QUICK := "slash_quick"
const ABILITY_SLASH_LIGHT := "slash_light"
const ABILITY_SLASH_WATER := "slash_water"
const ABILITY_ARROW_POISON := "arrow_poison"

## Secondary (RMB) — assign in main menu `secondary_ability`.
const ABILITY_FIRE_SLASH := "fire_slash"
const ABILITY_COMET := "comet"
const ABILITY_POISON_FLASK := "poison_flask"
const ABILITY_MOON_LASER := "moon_laser"
const ABILITY_NEPTUNE_SURGE := "neptune_surge"

## Used with integer division so changing stats auto-updates ★ ratings on the class screen.
static func value_to_stars(value: int, stat_min: int, stat_max: int) -> int:
	if stat_max <= stat_min:
		return 3
	var span: int = stat_max - stat_min
	var t: int = clampi(value - stat_min, 0, span)
	return clampi(1 + (t * 4) / span, 1, 5)
