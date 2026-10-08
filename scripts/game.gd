extends Node3D

const PLAYER_SCENE = preload("res://scenes/player.tscn")

@onready var player_spawner = $MultiplayerSpawner

func spawn_func(p: Array) -> Node3D:
	var ps = PLAYER_SCENE.instantiate() as Node3D
	print("name", name)
	ps.spawn_position = Vector3(p[2].x, 3, p[2].y)
	ps.get_node("Name").text = p[1]
	ps.set_multiplayer_authority(p[0])
	return ps

func _enter_tree():
	$MultiplayerSpawner.set_spawn_function(spawn_func)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.player_loaded.rpc_id(1)
	Global.all_players_loaded.connect(start_game)

func start_game():
	print('start game')
	print("peer_ids", Global.peer_id)
	print("players", Global.players)
	if is_multiplayer_authority():
		for peer_id in Global.players:
			var pos = Vector2(randf_range(-10, 10), randf_range(-10, 10))
			player_spawner.spawn([peer_id, Global.players[peer_id].name, pos])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
