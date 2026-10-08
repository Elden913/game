extends Area3D

@onready var timer: Timer = $Timer
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var particles: GPUParticles3D = $GPUParticles3D

var particle_mat: StandardMaterial3D
var nodelete:Array
var parent_collision_mask: int

func _ready() -> void:
	collision_mask = parent_collision_mask
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	
	# 1. Access Draw Pass 1 mesh material and duplicate it
	if particles.draw_pass_1 and particles.draw_pass_1.material:
		particles.draw_pass_1.material = particles.draw_pass_1.material.duplicate()
		particle_mat = particles.draw_pass_1.material as StandardMaterial3D
	
	# 2. Resizing shape logic
	if collision_shape and collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate()
		if collision_shape.shape is BoxShape3D:
			var side_length: float = ceil(pow(particles.amount, 1.0 / 3.0))
			collision_shape.shape.size += Vector3(side_length, 0.0, side_length)
			
func _physics_process(delta: float) -> void:
	for i in get_overlapping_areas():
		if !nodelete.has(i):
			i.queue_free()

func _on_timer_timeout() -> void:
	if particle_mat:
		#print("hi")
		queue_free()
	else:
		queue_free()
