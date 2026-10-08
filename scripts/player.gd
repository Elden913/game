# ProtoController v1.0 by Brackeys
# CC0 License
# Intended for rapid prototyping of first-person games.
# Happy prototyping!

extends CharacterBody3D

const PROJECTILES := {
	"ZOLTRAAK" : preload("res://scenes/zoltraak.tscn"),
	"TORNADO" : preload("res://scenes/tornado.tscn"),
	"BATK" : preload("res://mine/spells/BasicAttack/main.tscn")
}
const SHIELD := preload("res://mine/spells/shield/scene/main.tscn")
## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = false
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = true

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 7.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 10.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0

var vel: Vector3 = Vector3.ZERO

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "move_left"
## Name of Input Action to move Right.
@export var input_right : String = "move_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "move_up"
## Name of Input Action to move Backward.
@export var input_back : String = "move_down"
## Name of Input Action to Jump.
@export var input_jump : String = "move_jump"

@export var input_dash : String = "move_dash"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"



var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
@export var max_health: float = 200
@export var max_mana:float = 200
var player_health: float = max_health
var player_mana: float = max_mana



var dash_speed: float = 30.0
var dash_duration: float = 0.2
var dash_timer: float = 0.0
var is_dashing: bool = false
var dash_direction: Vector3 = Vector3.ZERO


var dash_cooldown: float = 2.0 # How many seconds before you can dash again
var dash_cooldown_timer: float = 0.0

var mana_regen_cooldown_timer :float= 0.0
var far:float = 100

## IMPORTANT REFERENCES
@onready var fake_head: Node3D = $FakeHead
@onready var static_camera: Node3D = $FakeHead/StaticCamera
@onready var head: Node3D = $Head
@onready var camera: Node3D = $Head/Camera3D
@onready var collider: CollisionShape3D = $Collider
@onready var raycast: RayCast3D = $Head/RayCast3D
@onready var dash_bar
@onready var health_bar
@onready var mana_bar

var spawn_position: Vector3

func _ready() -> void:
	global_position = spawn_position
	
	$Head/Camera3D.current = is_multiplayer_authority()
	if not is_multiplayer_authority():
		return
	set_collision_layer_value(2, true)
	set_collision_layer_value(3, false)
	health_bar = get_tree().current_scene.get_node("UI/HealthBar")
	health_bar.max_value = max_health
	health_bar.value = player_health
	mana_bar = get_tree().current_scene.get_node("UI/ManaBar")
	mana_bar.value = max_mana
	dash_bar = get_tree().current_scene.get_node("UI/DashCooldown")
	dash_bar.max_value = dash_cooldown
	dash_bar.value = dash_cooldown
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = fake_head.rotation.x
	head.reparent.call_deferred(get_tree().current_scene)

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	# Mouse capturing
	if Input.is_key_pressed(KEY_H):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func get_col_point() -> Vector3:
	var col_point: Vector3
	if raycast.is_colliding():
		col_point = raycast.get_collision_point()
	else:
		col_point = raycast.global_position + raycast.global_basis * (Vector3.FORWARD * 1000)
	return col_point
func debug_draw_cone(points: PackedVector3Array, trans: Transform3D):
	# Create a temporary mesh instance
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	mesh_instance.mesh = immediate_mesh
	
	# Add it to the main scene root so it stays in world space
	get_tree().root.add_child(mesh_instance)
	mesh_instance.global_transform = trans
	
	# Set up a simple unshaded material so it's clearly visible (e.g., bright green wireframe/lines)
	var mat = ORMMaterial3D.new()
	mat.shading_mode = ORMMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color.GREEN
	mesh_instance.material_override = mat
	
	# Draw the lines of the cone
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	var segments = 8
	# Points are ordered: [near_0, far_0, near_1, far_1, ...]
	for i in range(segments):
		var near_idx = i * 2
		var far_idx = i * 2 + 1
		var next_near_idx = ((i + 1) % segments) * 2
		var next_far_idx = ((i + 1) % segments) * 2 + 1
		
		# 1. Connect near point to far point (the sides of the cone)
		immediate_mesh.surface_add_vertex(points[near_idx])
		immediate_mesh.surface_add_vertex(points[far_idx])
		
		# 2. Draw the far ring connecting the base
		immediate_mesh.surface_add_vertex(points[far_idx])
		immediate_mesh.surface_add_vertex(points[next_far_idx])
		
		# 3. Draw lines from the center/near tip out to the ring if desired
		immediate_mesh.surface_add_vertex(points[near_idx])
		immediate_mesh.surface_add_vertex(points[next_near_idx])
		
	immediate_mesh.surface_end()
	
func crosshair_cone_cast(crosshair_angle_degrees: float = 1) -> Node3D:
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
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = cone_shape
	query.transform = camera.global_transform
	query.collision_mask = (1 << 2) # Layer 1 and Layer 3	
	# 3. Check for collisions inside the entire crosshair volume at once
	var results := space_state.intersect_shape(query)
	# debug_draw_cone(points, camera.global_transform)
	for result in results:
		print("res: ", result)
	if len(results) > 0:
		return results[0].collider
	else:
		return null

var active_shield: Node = null

@rpc("any_peer", "call_local", "reliable")
func shield():
	if is_instance_valid(active_shield):
		active_shield.queue_free()
	
	var sh = SHIELD.instantiate() as Area3D
	#if is_multiplayer_authority():
		#sh.set_collision_mask_value()
	add_child(sh)
	active_shield = sh
	get_tree().create_timer(1.0).timeout.connect(_on_shield_timer_timeout.bind(sh))

func _on_shield_timer_timeout(sh_instance) -> void:
	if is_instance_valid(active_shield) and active_shield == sh_instance:
		active_shield.queue_free()
		active_shield = null
@rpc("any_peer", "call_local", "reliable")
func shoot(projectile: String, start_point: Vector3, col_point: Vector3):
	is_mana_regen_fast = false
	is_mana_regen_slow = false	
	mana_regen_cooldown_timer = 3
	var p = PROJECTILES[projectile].instantiate() as Node3D
	if is_multiplayer_authority():
		p.collision_layer = (1 << 4)
	else:
		p.collision_layer = (1 << 3)
	mana_reduction(p.power)
	p.col_point = col_point
	p.start_point = start_point
	get_tree().current_scene.add_child(p)
	p.set_multiplayer_authority(Global.peer_id)

@rpc("any_peer", "call_local", "reliable")
func shoot_collider(projectile: String, start_point: Vector3, col_path: NodePath, start_basis:Basis):
	is_mana_regen_fast = false
	is_mana_regen_slow = false
	mana_regen_cooldown_timer = 3
	var col = get_node_or_null(col_path)
	var p = PROJECTILES[projectile].instantiate() as Node3D
	print("multiplayer authority: ", is_multiplayer_authority())
	if is_multiplayer_authority():
		p.collision_layer = (1 << 4)
	else:
		p.collision_layer = (1 << 3)
	p.col = col
	p.start_point = start_point
	p.start_basis = start_basis
	get_tree().current_scene.add_child(p)
	p.set_multiplayer_authority(Global.peer_id)

@rpc("any_peer", "call_local", "reliable")
func take_damage(damage: float):
	player_health = clampf(player_health-damage, 0, max_health)
	if player_health == 0:
		print("I died")
	if is_multiplayer_authority():
		health_bar.max_value = max_health
		health_bar.value = player_health
	
@rpc("any_peer", "call_local", "reliable")
func mana_reduction(val:float):
	player_mana = clampf(player_mana - val, 0, max_mana)
	if player_mana == 0:
		print("no mana")
	if is_multiplayer_authority():
		mana_bar.max_value = max_mana
		mana_bar.value = player_mana

var is_mana_regen_fast:bool = false
@rpc("any_peer", "call_local", "reliable")
func mana_regen_fast(delta:float) -> void:
	var val:float= 1
	player_mana = clampf(player_mana + val*delta, 0, max_mana)
	val*=1.1
	if player_mana == max_mana:
		is_mana_regen_fast = false
	if is_multiplayer_authority():
		mana_bar.max_value = max_mana
		mana_bar.value = player_mana
	
var is_mana_regen_slow:bool = false
@rpc("any_peer", "call_local", "reliable")
func mana_regen_slow(delta:float) -> void:
	var val:float= 0.4
	mana_regen_cooldown_timer = 5
	player_mana = clampf(player_mana + val*delta, 0, max_mana)
	val*=1.1
	if player_mana == max_mana:
		is_mana_regen_slow = false
	if is_multiplayer_authority():
		mana_bar.max_value = max_mana
		mana_bar.value = player_mana

func _physics_process(delta: float) -> void:
	mana_regen_cooldown_timer -= delta
	if delta == 0:
		is_mana_regen_fast = true
		is_mana_regen_slow = false
		mana_regen_fast.rpc(delta)
		print("regening mana")
	if not is_multiplayer_authority():
		return
	if Input.is_action_just_pressed("shoot1"):
		var col_point = get_col_point()
		var start_point = fake_head.global_position + fake_head.global_basis * Vector3.FORWARD * 2
		shoot.rpc("ZOLTRAAK", start_point, col_point, )
	if Input.is_action_just_pressed("shoot2"):
		var col_point = get_col_point()
		var start_point = fake_head.global_position + fake_head.global_basis * Vector3.FORWARD * 2
		shoot.rpc("TORNADO", start_point, col_point)
	if Input.is_action_just_pressed("shoot3"):
		var col := crosshair_cone_cast()
		var col_path: NodePath
		if col:
			col_path = col.get_path()
		var start_point = fake_head.global_position
		var start_basis = fake_head.global_basis
		shoot_collider.rpc("BATK", start_point, col_path, start_basis)
		print("testing man", collider)
	if Input.is_action_just_pressed("shield"):
		shield.rpc()
		is_mana_regen_fast = false
		is_mana_regen_slow = true
		mana_regen_slow.rpc(delta)
		
		
		
	head.global_position = head.global_position.lerp(static_camera.global_position, 0.2)
	head.global_basis = static_camera.global_basis
	# If freeflying, handle freefly and nothing else
	
	
	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			vel += get_gravity() * delta
	
	if can_freefly and freeflying:
		motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		# 1. Get WASD input
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		
		# 2. Translate 2D input into 3D space based on fake_head's rotation
		# Because fake_head rotates up/down, pressing W while looking up will fly you up.
		var move_dir := (fake_head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		# 3. Apply to velocity. 
		# We overwrite velocity completely to ignore gravity and existing momentum.
		velocity = move_dir * freefly_speed
		vel = Vector3.ZERO
		
		# 4. Slide against geometry instead of getting stuck
		move_and_slide()
		
		# Exit the physics frame early so normal walking/gravity logic doesn't run
		return
	else:
		motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED

	# Apply jumping
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			vel.y = jump_velocity

	# Modify speed based on sprinting
	if can_sprint and Input.is_action_pressed(input_sprint):
			move_speed = sprint_speed
	else:
		move_speed = base_speed
	
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
		if dash_bar:
			dash_bar.value = dash_cooldown - dash_cooldown_timer
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
	elif Input.is_action_just_pressed(input_dash) and can_move and dash_cooldown_timer <= 0:
		is_dashing = true
		dash_timer = dash_duration
		
		dash_cooldown_timer = dash_cooldown 
		if dash_bar:
			create_tween().tween_property(dash_bar, "value", 0, 0.2)
		
		# Figure out which way to dash based on WASD
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		if input_dir != Vector2.ZERO:
			dash_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		else:
			# If standing still, default to dashing forward
			dash_direction = -transform.basis.z
	
	if not is_dashing:
		# --- YOUR NORMAL MOVEMENT OVERRIDDEN BY DASH ---
		if can_move:
			var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
			var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			if move_dir:
				vel.x = move_dir.x * move_speed
				vel.z = move_dir.z * move_speed
			else:
				vel.x = move_toward(vel.x, 0, move_speed)
				vel.z = move_toward(vel.z, 0, move_speed)
		else:
			vel.x = 0
			vel.z = 0 # Changed from vel.y = 0 so you don't float mid-air when can_move is false
	else:
		# --- DASH MOVEMENT ---
		# We strictly override X and Z, leaving Y alone so gravity/jumping still apply mid-dash
		vel.x = dash_direction.x * dash_speed
		vel.z = dash_direction.z * dash_speed
	
	velocity = vel
	
	# Use velocity to actually move
	move_and_slide()


## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	
	rotate_y(look_rotation.y)
	fake_head.transform.basis = Basis()
	fake_head.rotate_x(look_rotation.x)

func enable_freefly():
	freeflying = true
	vel = Vector3.ZERO

func disable_freefly():
	freeflying = false


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false
