extends Node2D

@onready var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
@onready var label: Label = $Label

const BASE_TEXT := " "

var active_areas: Array[InteractionArea] = []
var can_interact = true


func register_area(area: InteractionArea) -> void:
	if area != null and not active_areas.has(area):
		active_areas.push_back(area)
	
func unregister_area(area: InteractionArea) -> void:
	var index = active_areas.find(area)
	if index != -1:
		active_areas.remove_at(index)


func _process(_delta: float) -> void:
	var area := _current_area()
	if area == null or not can_interact:
		label.hide()
		return

	label.text = BASE_TEXT + area.action_name
	label.global_position = area.global_position
	label.global_position.y -= 36
	label.global_position.x -= label.size.x / 2
	label.show()


func _current_area() -> InteractionArea:
	_clean_active_areas()
	if active_areas.is_empty():
		return null
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
		if not is_instance_valid(player):
			return null
	active_areas.sort_custom(_sort_by_distance_to_player)
	return active_areas[0]


func _clean_active_areas() -> void:
	var clean_areas: Array[InteractionArea] = []
	for area in active_areas:
		if is_instance_valid(area) and area.monitoring:
			clean_areas.push_back(area)
	active_areas = clean_areas


func _sort_by_distance_to_player(area1: InteractionArea, area2: InteractionArea) -> bool:
	var area1_to_player = player.global_position.distance_to(area1.global_position)
	var area2_to_player = player.global_position.distance_to(area2.global_position)
	return area1_to_player < area2_to_player


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or not can_interact:
		return

	var area := _current_area()
	if area == null:
		return

	can_interact = false
	label.hide()
	area.activate()
	can_interact = true
