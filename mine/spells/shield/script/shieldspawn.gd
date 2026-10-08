extends Area3D

@export var Shield:PackedScene
@export var Broken:PackedScene

@export var D:float = 2.5
@export var shieldpower:int = 999

var cnt:int

func _ready() -> void:
	pass # Replace with function body.

func _physics_process(_delta: float) -> void:
	var objects = get_overlapping_areas()
	cnt = objects.size() - 1
	for i in objects:
		cnt -= 1
		var dir = (global_position - i.global_position).normalized()
		var offvec = dir * D
		var shieldpos = i.global_position + offvec
		
		# Ensure shieldpos stays in front of the collider, but never closer than D * 1.5 to player
		if global_position.distance_to(shieldpos) < (D * 1.5):
			shieldpos = global_position - (dir * D * 1.5)

		if cnt >= 0:
			if shieldpower >= i.power:
				_spawn_shield(shieldpos, i.power, global_position.distance_to(i.global_position))
			else: 
				_spawn_brokenshield(shieldpos, i.power, global_position.distance_to(i.global_position))
		else:
			if shieldpower >= i.power:
				_spawn_shield(shieldpos, i.power, global_position.distance_to(i.global_position))
			else: 
				_spawn_brokenshield(shieldpos, i.power, global_position.distance_to(i.global_position))
			_ending()

func _spawn_shield(pos: Vector3, powerr: int, rad: float) -> void:
	if !Shield:
		return
		
	var Shi = Shield.instantiate() as Node3D
	shieldpower -= powerr
	get_tree().current_scene.add_child(Shi)
	Shi.global_position = pos
	
	# 1. Access GPUParticles3D correctly via get_node()
	var particles = Shi.get_node_or_null("GPUParticles3D") as GPUParticles3D
	if particles:
		particles.amount = powerr
		if particles.process_material is ShaderMaterial:
			(particles.process_material as ShaderMaterial).set_shader_parameter("sphere_radius", rad)

	Shi.look_at(global_position, Vector3.UP)
	Shi.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))

	if particles:
		particles.restart()
		particles.emitting = true

func _spawn_brokenshield(pos: Vector3, powerr:int, rad: float) -> void:
	if !Broken: return
	var Bro = Broken.instantiate() as Node3D
	get_tree().current_scene.add_child(Bro)
	var particles = Bro.get_node_or_null("GPUParticles3D") as GPUParticles3D
	if particles: 
		particles.amount = ceil(randf_range(0.3, 0.7)*powerr)
		if particles.process_material is ShaderMaterial:
			(particles.process_material as ShaderMaterial).set_shader_parameter("sphere_radius", rad)
	
	Bro.global_position = pos
	Bro.look_at(global_position, Vector3.UP)
	Bro.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
	
	if particles:
		particles.restart()
		particles.emitting = true

func _ending() -> void:
	queue_free()
