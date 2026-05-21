extends Control

@export var action_key: String = "E"
@export var ability_icon: Texture2D

var cooldown_ratio: float = 0.0


func set_ability_icon(tex: Texture2D) -> void:
	ability_icon = tex
	queue_redraw()


func _ready() -> void:
	var lbl := get_node_or_null("KeyLabel")
	if lbl:
		lbl.text = action_key


func set_cooldown_remaining(remaining: float, total: float) -> void:
	if total <= 0.0:
		cooldown_ratio = 0.0
	else:
		cooldown_ratio = clampf(remaining / total, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = mini(size.x, size.y) * 0.5 - 4.0
	if ability_icon:
		var dim: float = (r - 2.0) * 2.0 * 0.72
		var sz := Vector2(dim, dim)
		var rect := Rect2(c - sz * 0.5, sz)
		draw_texture_rect(ability_icon, rect, false)

	var inner_r: float = r - 3.0
	draw_arc(c, inner_r, 0.0, TAU, 64, Color(0.12, 0.11, 0.16, 0.92), r * 0.22)
	draw_arc(c, inner_r - 1.0, 0.0, TAU, 64, Color(0.35, 0.32, 0.42, 0.6), 2.0)
	if cooldown_ratio > 0.001:
		var start := -PI * 0.5
		var sweep: float = TAU * cooldown_ratio
		var steps: int = maxi(8, int(48.0 * cooldown_ratio) + 4)
		draw_arc(c, inner_r - 2.0, start, start + sweep, steps, Color(0.05, 0.05, 0.08, 0.88), (inner_r - 2.0) * 0.32)
