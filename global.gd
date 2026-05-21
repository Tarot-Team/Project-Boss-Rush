extends Node

var player_class: Dictionary = {}


func active_primary_ability() -> String:
	if player_class.has("primary_ability") and str(player_class["primary_ability"]) != "":
		return AbilityKit.normalize_ability_id(player_class["primary_ability"])
	return AbilityKit.default_primary_for_character(String(player_class.get("id", "mars")))


func active_secondary_ability() -> String:
	if player_class.has("secondary_ability") and str(player_class["secondary_ability"]) != "":
		return AbilityKit.normalize_ability_id(player_class["secondary_ability"])
	return AbilityKit.default_secondary_for_character(String(player_class.get("id", "mars")))


## Call from pickups / card rewards after mutating `player_class` abilities.
func apply_player_abilities_to_runtime(player_root: Node) -> void:
	if player_root and player_root.has_method("refresh_ability_loadout"):
		player_root.refresh_ability_loadout()
