extends Node


const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS = 20

var name_text_input = ""
var players = {}
var peer_id = 1
var player_info = {"name": "Name"}
var players_loaded = 0

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected
signal all_players_loaded

const ROOM_SCENE = preload("res://scenes/lobby.tscn")

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func set_player_info(peer_id):
	var name = name_text_input.strip_edges()
	Global.player_info.name = name if not name.is_empty() else "dumb perso " + str(peer_id)

func join_game(address):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, Global.PORT)
	if error:
		return error
	multiplayer.multiplayer_peer = peer


func create_game():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(Global.PORT, Global.MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	peer_id = multiplayer.get_unique_id()
	set_player_info(peer_id)

	Global.players[1] = Global.player_info
	player_connected.emit(1, Global.player_info)
	get_tree().change_scene_to_file("res://scenes/room.tscn")


func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	Global.players.clear()


# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id):
	_register_player.rpc_id(id, Global.player_info)
	print("current Global.players:", Global.players)


@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	Global.players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)
	print("new player:", Global.players)


func _on_player_disconnected(id):
	Global.players.erase(id)
	player_disconnected.emit(id)

func _on_connected_ok():
	peer_id = multiplayer.get_unique_id()
	set_player_info(peer_id)
	Global.players[peer_id] = Global.player_info
	player_connected.emit(peer_id, Global.player_info)
	get_tree().change_scene_to_file("res://scenes/room.tscn")


func _on_connected_fail():
	remove_multiplayer_peer()


func _on_server_disconnected():
	remove_multiplayer_peer()
	Global.players.clear()
	server_disconnected.emit()

@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded == players.size():
			all_players_loaded.emit()
			players_loaded = 0

@rpc("call_local", "reliable")
func load_game(game_scene_path):
	get_tree().change_scene_to_file(game_scene_path)
