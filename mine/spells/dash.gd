extends Area3D
@onready var timer: Timer = $Timer
@onready var timer_2: Timer = $Timer2
@onready var plr = get_parent()

func _ready() -> void:
	area_entered.connect(disable_projectile)
	body_entered.connect(disable_projectile)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func disable_projectile(col: Node) -> void:
	if "is_tracking" in col:
		col.is_tracking = false

@rpc("any_peer", "call_local", "reliable")
func start_dashing():
	print("start dash")
	monitoring = true
	plr.can_take_damage = false
	timer.start()
	timer_2.start()

func _on_timer_timeout() -> void:
	monitoring = false
	pass # Replace with function body.

func _on_timer_2_timeout() -> void:
	plr.can_take_damage = true
	pass # Replace with function body.
