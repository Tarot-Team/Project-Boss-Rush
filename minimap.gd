extends Control

var visited_rooms = [] # Array of Vector2
var connections = [] # Array of Dictionaries {"from": Vector2, "to": Vector2}
var current_room_center = Vector2.ZERO
var start_room_center = Vector2.ZERO

@export var map_scale: float = 0.03
@export var room_size: Vector2 = Vector2(16, 16)

func _ready():
	clip_contents = true

func clear():
	visited_rooms.clear()
	connections.clear()
	queue_redraw()

func init_map(start_center: Vector2):
	clear()
	start_room_center = start_center
	current_room_center = start_center
	visited_rooms.append(start_center)
	queue_redraw()

func visit_room(prev_center: Vector2, new_center: Vector2):
	if not new_center in visited_rooms:
		visited_rooms.append(new_center)
		
	var conn = {"from": prev_center, "to": new_center}
	var rev_conn = {"from": new_center, "to": prev_center}
	if not conn in connections and not rev_conn in connections:
		connections.append(conn)
		
	current_room_center = new_center
	queue_redraw()

func _draw():
	var center_offset = size / 2
	
	# Draw connections
	for conn in connections:
		var from_map = (conn["from"] - current_room_center) * map_scale + center_offset
		var to_map = (conn["to"] - current_room_center) * map_scale + center_offset
		draw_line(from_map, to_map, Color(0.6, 0.6, 0.6), 4.0)
		
	# Draw rooms
	for room_pos in visited_rooms:
		var map_pos = (room_pos - current_room_center) * map_scale + center_offset
		var rect = Rect2(map_pos - room_size / 2, room_size)
		
		var color = Color(0.8, 0.8, 0.8) # Visited (White/Gray)
		if room_pos == start_room_center:
			color = Color(1.0, 0.95, 0.6) # Lighter Yellow for start
		if room_pos == current_room_center:
			color = Color(0.3, 0.8, 1.0) # Blue for current
			
		draw_rect(rect, color)
		draw_rect(rect, Color.BLACK, false, 2.0) # Border
