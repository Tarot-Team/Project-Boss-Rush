extends CanvasLayer

@onready var HealthProg = $ProgressBar
@onready var BossName = $RichTextLabel

func _ready():
	var Boss = get_tree().get_first_node_in_group("boss")
	if Boss == null:
		return
	Boss.bosshealth_changed.connect(change_healthbar)
	Boss.sethealthbar.connect(set_healthmax)
	Boss.setname.connect(setname)
	set_healthmax(Boss.max_health)
	change_healthbar(Boss.health)
	setname(Boss.boss_name)
	show_healthbar()

func setname(string):
	BossName.text = string

func set_healthmax(value):
	HealthProg.max_value = value

func change_healthbar(value):
	HealthProg.value = value

func show_healthbar():
	$AnimationPlayer.play("fade in")

func hide_healthbar():
	$AnimationPlayer.play("fade out")

var dead = false

func _process(_delta):
	if HealthProg.value <= 0 and not dead:
		dead = true
		hide_healthbar()


func _on_timer_timeout():
	queue_free()
