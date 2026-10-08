extends Area3D

@export var Shield: PackedScene
@export var Broken: PackedScene

@export var D: float = 2.5
@export var shieldpower: int = 999
@onready var timer: Timer = $Timer

var cnt: int
var blocked:Array
var nodelete:Array
var plr:Node3D

func _ready() -> void:
	timer.start()
	pass

func _physics_process(_delta: float) -> void:
	shieldpower = plr.player_mana
	var objects = get_overlapping_areas()
	
	# If nothing is overlapping yet, keep waiting
	if objects.is_empty():
		return
		
	cnt = objects.size() - 1
	print("Spawning for objects count: ", objects.size())
	
	for i in objects:
		if !blocked.has(i):
			blocked.append(i)
			cnt -= 1
			var dir = (global_position - i.global_position).normalized()
			var offvec = dir * D
			var shieldpos = i.global_position + offvec
			
			# Ensure shieldpos stays in front of the collider, but never closer than D * 1.5 to player
			if global_position.distance_to(shieldpos) < (D * 1.5):
				shieldpos = global_position - (dir * D * 1.5)

			# Unified spawn logic (no duplication)
			var rad = global_position.distance_to(i.global_position)
			if shieldpower >= i.power:
				plr.mana_reduction(i.power/1.5)
				_spawn_shield(shieldpos, i.power, rad)
			else: 
				_spawn_brokenshield(shieldpos, i.power, rad)

func _spawn_shield(pos: Vector3, powerr: int, rad: float) -> void:
	if !Shield:
		return
		
	var Shi = Shield.instantiate() as Node3D
	shieldpower -= powerr
	Shi.parent_collision_mask = collision_mask
	get_tree().current_scene.add_child(Shi)
	blocked.append(Shi)
	Shi.global_position = pos
	
	var particles = Shi.get_node_or_null("GPUParticles3D") as GPUParticles3D
	if particles:
		particles.amount = powerr
		if particles.process_material is ShaderMaterial:
			(particles.process_material as ShaderMaterial).set_shader_parameter("sphere_radius", rad)

	Shi.look_at(global_position, Vector3.UP)
	Shi.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
	Shi.nodelete = nodelete
	Shi.nodelete.append(self)
	

	if particles:
		particles.restart()
		particles.emitting = true

func _spawn_brokenshield(pos: Vector3, powerr: int, rad: float) -> void:
	if !Broken: 
		return
		
	var Bro = Broken.instantiate() as Node3D
	get_tree().current_scene.add_child(Bro)
	blocked.append(Bro)
	
	var particles = Bro.get_node_or_null("GPUParticles3D") as GPUParticles3D
	if particles: 
		particles.amount = int(ceil(randf_range(0.3, 0.7) * float(powerr)))
		if particles.process_material is ShaderMaterial:
			(particles.process_material as ShaderMaterial).set_shader_parameter("sphere_radius", rad)
	
	Bro.global_position = pos
	Bro.look_at(global_position, Vector3.UP)
	
	if particles:
		particles.restart()
		particles.emitting = true

func _on_timer_timeout() -> void:
	queue_free()
	pass # Replace with function body.
