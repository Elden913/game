extends HSlider

func show_player_health(player_health: float, max_health: float):
	print("setting health to: ", player_health, " ", max_health)
	max_value = max_health
	value = player_health

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
