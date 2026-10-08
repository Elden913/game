extends Area3D

@export var speed0: float = 40
var dist:float
var accel: float = 100
@export var up: float = 1.0
@export var turn_speed: float = 5
@onready var timer: Timer = $Timer
var power:float = 10
@export var acc:float = 10
# Export PackedScenes so you can drop particle .tscn files into the Inspector
@export var explosion_scene: PackedScene
@export var spark_scene: PackedScene
@export var trail_scene: PackedScene
@export var smoke_scene1: PackedScene
@export var smoke_scene2: PackedScene	

var velocity: Vector3 = Vector3.ZERO
var collider:Node3D
var dists:float

var accx= randf_range(-acc-1, acc+1)
var accy= randf_range(-acc-1, acc+1)
var accz= randf_range(-acc-1, acc+1)

@onready var current_speed: float = speed0
var t: float = 4.0
var changetime: float = 0.0
var p_pos:Vector3
var p_ang:Basis

func _ready() -> void:
	accel = randf_range(0, accel)
	timer.start()
	
func setup() -> void:
	var dir = (global_position - p_pos).normalized()
	dir.y = randf_range(0.2, 3)
	look_at(global_position+dir,Vector3.UP)
	

func _physics_process(delta: float) -> void:
	# 1. Safely check collider validity
	if is_instance_valid(collider):
		var target_pos = collider.global_position
		if global_position.distance_squared_to(target_pos) >= 0.001:
			if t >= 1: 
				t = 0
				turn_speed *= 1.1
			var trans = global_transform.looking_at(target_pos, Vector3.UP)
			global_basis = global_basis.slerp(trans.basis, turn_speed * delta)

	t += delta
	changetime += delta
	current_speed += accel * delta
	
	# 3. Use world-space basis for global_position movement
	var forward = global_transform.basis.z * current_speed * delta
	
	global_position -= forward
	
	# 4. Include delta so mesh decay rate is frame-rate independent
	var reduction = current_speed * 0.01 * delta
	if $MeshInstance3D.scale.x - reduction > 0.5:
		$MeshInstance3D.scale.x -= reduction
		$MeshInstance3D.scale.y -= reduction

func _on_body_entered(body: Node) -> void:
	print("hit: ", body.name)
	
	_spawn_effect(explosion_scene)
	_spawn_effect(spark_scene)
	_spawn_effect(trail_scene)
	_spawn_effect(smoke_scene1)
	_spawn_effect(smoke_scene2)
	queue_free()

# Helper function to safely spawn and play effects at collision position
func _spawn_effect(scene: PackedScene) -> void:
	if scene:
		var fx = scene.instantiate() as GPUParticles3D
		get_tree().current_scene.add_child(fx)
		fx.global_position = global_position
		fx.restart()
		fx.emitting = true

func _on_timer_timeout() -> void:
	queue_free()
	pass # Replace with function body.
