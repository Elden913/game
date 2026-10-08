extends Area3D

@export var power: int = 10
@export var speed: float = 10.0

func _ready() -> void:
	# Ensure signals are connected
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	var dir_to_center: Vector3 = (Vector3.ZERO - global_position).normalized()
	global_position += dir_to_center * speed * delta

func _on_body_entered(body: Node3D) -> void:
	print("Body entered: ", body.name)
	queue_free()
