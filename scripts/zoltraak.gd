extends Area3D

@export var speed: float = 40.0
@export var max_range: float = 100.0
@export var rot_speed: float = 2.0
@export var magic_circle_scale: float = 3.0
@export var magic_circle_curve: Curve

@export var power: int = 5

var start_point: Vector3
var col_point: Vector3

const PARTICLES_SCENE = preload("res://scenes/combined particles.tscn")

var current_length: float
var is_moving: bool = false
var has_hit: bool = false


func _ready() -> void:
	global_position = start_point
	look_at(col_point)
	var tween = create_tween()
	tween.tween_property($MagicCircle, "scale", Vector3.ONE * magic_circle_scale, 0.5).set_custom_interpolator(magic_circle_curve.sample)
	tween.tween_callback(fire_projectile)

func fire_projectile():
	is_moving = true

func _physics_process(delta: float) -> void:
	$MagicCircle.rotate_object_local(Vector3.FORWARD, rot_speed * delta)
	
	if is_moving and not has_hit:
		# Increase the length of the beam over time
		current_length += speed * delta
		
		# 1. Stretch the cylinder
		$MeshInstance3D.mesh.height = current_length
		
		# 2. Offset the mesh so the base stays exactly on the magic circle
		$MeshInstance3D.position.z = -current_length * 0.5
		
		# 3. Move the collision shape to act as the "Tip" of the beam
		$CollisionShape3D.position.z = -current_length
		if current_length >= max_range:
			has_hit = true
			fade_out_and_destroy()

func _on_body_entered(body: Node3D):
	if has_hit:
		return 
		
	if body.get_collision_layer_value(3):
		if is_multiplayer_authority():
			body.take_damage.rpc(10)
		
	has_hit = true
	
	var hit_pos = $CollisionShape3D.global_position
	spawn_particles(hit_pos)
	
	fade_out_and_destroy()

# Reusable function to shrink and delete the projectile
func fade_out_and_destroy():
	is_moving = false
	var tween = create_tween()
	tween.parallel().tween_property($MagicCircle, "scale", Vector3.ZERO, 0.2).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property($MeshInstance3D, "mesh:radius", 0, 0.2)
	tween.tween_callback(queue_free)

func spawn_particles(pos: Vector3):
	var particles = PARTICLES_SCENE.instantiate() as Node3D
	get_tree().current_scene.add_child(particles)
	particles.global_position = pos
	
	particles.get_child(0).restart()
	particles.get_child(1).restart()
	particles.get_child(2).restart()
	
	var timer = Timer.new()
	timer.wait_time = 2.5
	timer.one_shot = true
	timer.timeout.connect(func (): particles.queue_free())
	particles.add_child(timer)
	timer.start()
