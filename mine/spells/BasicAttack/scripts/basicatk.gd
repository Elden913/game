extends Node3D

@export var far: float = 100
@export var summon: PackedScene
@export var spawnoffset: float = 3
@export var power:float = 5.0
var col:Node3D
var start_point:Vector3
var start_basis: Basis

func _ready() -> void:
	await get_tree().process_frame
	global_basis = start_basis
	global_position = start_point
	_setup()

func _setup() -> void:
	var look: Basis = global_transform.basis
	var offset:Vector3 = _rand_vect()
	if start_point.distance_to(start_point+offset) <= 3:
		offset = _rand_vect()
	var spawn_pos := start_point + offset
	
	_summon(summon, spawn_pos, look)

func _summon(scene_to_spawn: PackedScene, pos: Vector3, dir: Basis) -> void:
	if not scene_to_spawn:
		push_warning("Summon scene is not assigned!")
		return
	var fx = scene_to_spawn.instantiate()
	if fx is Node3D:
		fx.power = power
		var parent = get_tree().current_scene if get_tree().current_scene else get_parent()
		
		parent.add_child.call_deferred(fx)

		await fx.tree_entered
		_setup_fx(fx, pos, dir, col)

func _setup_fx(fx: Node3D, pos: Vector3, dir: Basis, targ: Node3D) -> void:
	if is_instance_valid(fx) and fx.is_inside_tree():
		fx.global_position = pos
		fx.global_transform.basis = dir
		if targ: 
			fx.targ = col

		if fx.has_method("_run"):
			fx._run()

func _rand_vect() -> Vector3:
	var v = Vector3(
		randf_range(-spawnoffset, spawnoffset),
		randf_range(0.2, spawnoffset),
		randf_range(-spawnoffset, -.1)
	)
	return v
