extends Node3D

@export var far: float = 100
@export var summon: PackedScene
@export var power: float = 5.0

var col: Node3D
var start_point: Vector3 # This receives the exact calculated start_pos from the player!
var start_basis: Basis
var collision_layer: int
var authority: int

func _ready() -> void:
	set_multiplayer_authority(authority)
	await get_tree().process_frame
	global_basis = start_basis
	global_position = start_point
	
	# Spawn it immediately at the start_point provided by the player
	_summon(summon, start_point, start_basis)

func _summon(scene_to_spawn: PackedScene, pos: Vector3, dir: Basis) -> void:
	if not scene_to_spawn:
		push_warning("Summon scene is not assigned!")
		return
		
	var fx = scene_to_spawn.instantiate()
	if fx is Node3D:
		fx.authority = authority
		fx.collision_layer = collision_layer
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
			fx.targ = targ
		fx._run()
