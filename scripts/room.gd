extends Node3D


# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)


func get_local_ip() -> String:
	var addresses = IP.get_local_addresses()
	
	for addr in addresses:
		if addr.split(".").size() == 4 and not addr.begins_with("127."):
			if not addr.begins_with("169.254."):
				return addr
				
	return "127.0.0.1"

func _ready()-> void:
	if is_multiplayer_authority():
		$Control/IPLabel.text = str(get_local_ip())
	Global.player_connected.connect(on_player_connected)
	$Control/Button.disabled = not is_multiplayer_authority()

	for p in Global.players.values():
		$Control/ItemList.add_item(p.name)
	pass # Replace with function body.

func on_player_connected(peer_id, player_info):
	$Control/ItemList.add_item(player_info.name)

func _on_button_pressed():
	Global.load_game.rpc("res://scenes/game.tscn")
