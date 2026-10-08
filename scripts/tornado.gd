extends Area3D

@export var speed: float = 40.0
@export var max_range: float = 100.0
@export var tornado_spawn_curve: Curve
@export var power: int = 5

var current_distance: float
var is_moving: bool = false
var has_hit: bool = false


var start_point: Vector3
var col_point: Vector3
var authority: int

func _ready() -> void:
	set_multiplayer_authority(authority)
	global_position = start_point
	global_position.y = 0
	
	# Create a level target point
	var flat_col_point = Vector3(col_point.x, 0, col_point.z)
	look_at(flat_col_point)
	var tween = create_tween()
	scale = Vector3(0.001,0.001,0.001)
	tween.tween_property(self, "scale", Vector3.ONE, 0.5).set_custom_interpolator(tornado_spawn_curve.sample)
	tween.tween_callback(start_moving)

func start_moving() -> void:
	is_moving = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_moving:
		if is_moving and not has_hit:
			current_distance += speed * delta
			translate(Vector3.FORWARD * speed * delta)
			if current_distance >= max_range:
				has_hit = true
				fade_out_and_destroy()

func _on_body_entered(body: Node3D):
	if has_hit:
		return
	
	print("hit something niger")
	if body.get_collision_layer_value(3):
		if is_multiplayer_authority():
			body.take_damage.rpc(30)
		
	has_hit = true
	
	# var hit_pos = $CollisionShape3D.global_position
	# spawn_particles(hit_pos)
	fade_out_and_destroy()

func fade_out_and_destroy():
	is_moving = false
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector3(0.001, 0.001, 0.001), 0.2).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(queue_free)
