extends Node3D

var collider: Node3D

@export var projectile: PackedScene
@export var bob_dur: float = 1.5
@export var randn: float = 0.8
@export var height: float = 1.5
@export var m: float = 5.0
@export var spiral_radius: float = 1.5   # Maximum distance from the fixed center

@export var center_position: Vector3
var spiral_turns: float
var random_angle_offset: float

var _target_y: float

func _ready() -> void:
	# Randomize spiral loops and starting angle
	spiral_turns = randf_range(0.5, 2.0)
	random_angle_offset = randf_range(0.0, TAU)

	# If center_position wasn't explicitly set before add_child(), default to current global position
	if center_position == Vector3.ZERO:
		center_position = global_position

	_start_animation()

func _start_animation() -> void:
	var stept: float = bob_dur / 2.0
	var total_dur: float = stept * 2.0
	_target_y = center_position.y + randf_range(-2.0, height + 1.0)

	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# 1. Scale up
	tween.parallel().tween_property(self, "scale", scale * m, stept)
	# 2. Animate global Y position to keep transform space consistent
	tween.parallel().tween_property(self, "global_position:y", _target_y, stept)
	# 3. Animate horizontal spiral offset
	tween.parallel().tween_method(_update_spiral_offset, 0.0, 1.0, total_dur)
	
	# Chain sequence: spawn projectile when done, then free self
	tween.chain().tween_callback(_spawn_projectile.bind(projectile))
	tween.tween_callback(queue_free)

func _update_spiral_offset(progress: float) -> void:
	var angle := (progress * spiral_turns * TAU) + random_angle_offset
	
	var offset_x := cos(angle) * spiral_radius
	var offset_z := sin(angle) * spiral_radius

	global_position.x = center_position.x + offset_x
	global_position.z = center_position.z + offset_z

func _spawn_projectile(scene: PackedScene) -> void:
	if not scene:
		push_warning("Projectile scene is null!")
		return

	var projectile2 = scene.instantiate() as Node3D
	if projectile2:
		# Pass parameters safely
		if "p_pos" in projectile2: projectile2.p_pos = center_position
		if "p_ang" in projectile2: projectile2.p_ang = global_basis
		
		# Safely calculate distance only if collider is valid
		if is_instance_valid(collider):
			if "dists" in projectile2:
				projectile2.dists = global_position.distance_to(collider.global_position)
			if "collider" in projectile2:
				projectile2.collider = collider
		else:
			if "dists" in projectile2:
				projectile2.dists = 0.0

		get_tree().current_scene.add_child(projectile2)
		projectile2.global_position = global_position
		
		if projectile2.has_method("setup"):
			projectile2.setup()
			
		print("Spawned projectile at: ", global_position)
