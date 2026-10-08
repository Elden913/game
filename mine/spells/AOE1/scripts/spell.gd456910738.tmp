extends Node3D

@export var load_scene: PackedScene 
@export var cnt: int = 3
@export var randn: float = 0.8
@export var far:float = 100

@onready var arcane1: GPUParticles3D = $arcane1
@onready var arcane2: GPUParticles3D = $arcane2

var collide:Node3D

func crosshair_cone_cast(crosshair_angle_degrees: float = 3.0) -> void:
	var space_state = get_world_3d().direct_space_state
	
	# Calculate how wide the cone needs to be at 'far_distance'
	var far_radius = tan(deg_to_rad(crosshair_angle_degrees)) * far
	var near_radius = 0.1 # Small starting radius at the nozzle/camera
	
	# 1. Build a Frustum (expanding cone) shape matching the crosshair FOV
	var cone_shape = ConvexPolygonShape3D.new()
	var points = PackedVector3Array()
	var segments = 8 # 8 points around the circle creates an 8-sided cone
	
	for i in range(segments):
		var angle = i * TAU / segments
		var cos_a = cos(angle)
		var sin_a = sin(angle)
		
		# Tip / Near points (near origin)
		points.append(Vector3(cos_a * near_radius, sin_a * near_radius, 0))
		# Base / Far points (expanded at far_distance in forward direction -Z)
		points.append(Vector3(cos_a * far_radius, sin_a * far_radius, -far))
		
	cone_shape.points = points
	
	# 2. Query the physics space for anything inside this cone
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = cone_shape
	query.transform = global_transform
	
	# 3. Check for collisions inside the entire crosshair volume at once
	var results = space_state.intersect_shape(query)
	
	for result in results:
		collide = result.collider
		print("Hit inside crosshair area: ", collide.name)
		
		# Spawn logic around the hit targets
		if arcane1: arcane1.emitting = true
		if arcane2: arcane2.emitting = true
		
		for i in range(cnt):
			var rx = randf_range(-1, 1)
			var rz = randf_range(-1, 1)
			var ry = randf_range(0, 1)
			_spawn(load_scene, result.collider.global_position + Vector3(rx, ry, rz))

func _ready() -> void:
	await get_tree().process_frame
	crosshair_cone_cast()

func _spawn(scene: PackedScene, x:Vector3) -> void:
	if scene == null:
		push_error("load_scene is missing in the Inspector!")
		return

	# Cast to Node3D so it accepts Area3D, GPUParticles3D, MeshInstance3D, etc.
	var fx = scene.instantiate() as Node3D
	
	if fx:
		fx.center_position = global_position + Vector3(0,2.7,0)
		get_tree().current_scene.add_child(fx)
		fx.global_position = global_position + x
		fx.center_position = global_position
		fx.global_basis = global_basis
		fx.collider = collide
		#print("Spawned effect at: ", fx.global_position)
	else:
		push_error("Instantiated scene is not derived from Node3D!")
