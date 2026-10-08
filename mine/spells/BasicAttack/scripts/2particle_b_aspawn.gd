extends GPUParticles3D

@onready var timer: Timer = $Timer
@export var projectile:PackedScene
var targ:Node3D
var power: float
var collision_layer: int
var authority: int

func _ready() -> void:
	set_multiplayer_authority(authority)
	timer.start()	
	pass # Replace with function body.

func _run() -> void:
	emitting = true
	$Econc.emitting = true
	$energyparticles.emitting = true

func _on_timer_timeout() -> void:
	var fx = projectile.instantiate()
	fx.power = power
	fx.targ = targ
	fx.authority = authority
	get_tree().current_scene.add_child(fx)
	fx.collision_layer = collision_layer
	fx.global_position = position + Vector3(0, 0, -0.25)
	fx.global_basis = global_basis
	queue_free()
