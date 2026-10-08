extends Area3D

@export var hitfx: PackedScene
@export var turn_speed: float = 7.0
@export var max_turn_speed: float = 50.0
@export var speed: float = 20.0
@export var maxdist = 50

var targ: Node3D
var t: float = 0.0
var is_tracking: bool = true
var dist:float = 0
var power: float
var authority: int

func _ready() -> void:
	set_multiplayer_authority(authority)

func _physics_process(delta: float) -> void:
	if dist >= maxdist: queue_free()
	if is_tracking and is_instance_valid(targ):
		var target_pos = targ.global_position + Vector3(0 ,1 ,0)
		
		# Prevent looking_at errors if target is at the exact same position
		if global_position.distance_squared_to(target_pos) > 0.01:
			# Increment turn speed every second
			t += delta
			if t >= 1.0:
				t = 0.0
				turn_speed = minf(turn_speed * 3, max_turn_speed)

			# Safe UP vector check to prevent crashes when looking straight up/down
			var dir = global_position.direction_to(target_pos)
			var up_dir = Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
			
			# Calculate target basis and smoothly rotate toward it
			var target_transform = global_transform.looking_at(target_pos, up_dir)
			var weight = clampf(turn_speed * delta, 0.0, 1.0)
			var normalized_basis = Quaternion(global_basis).normalized()
			
			global_basis = normalized_basis.slerp(Quaternion(target_transform.basis).normalized(), weight) 	

	# Move forward along local -Z axis (Godot 4 idiomatic)
	global_position += -transform.basis.z * speed * delta
	dist+= speed*delta

func _on_body_entered(body: Node3D) -> void:
	if body.get_collision_layer_value(3):
		if is_multiplayer_authority():
			body.take_damage.rpc(10)
	var fx = hitfx.instantiate()
	get_tree().current_scene.add_child(fx)
	fx.global_position = global_position
	fx.emitting = true
	visible = false
	await get_tree().create_timer(0.5).timeout
	fx.queue_free()
	queue_free()
