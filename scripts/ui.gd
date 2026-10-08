extends Control



func _on_server_button_pressed() -> void:
	Global.name_text_input = $NameTextEdit.text
	Global.create_game()

func _on_client_button_pressed() -> void:
	Global.name_text_input = $NameTextEdit.text
	var ip = $IPTextEdit.text.strip_edges()
	Global.join_game(ip if not ip.is_empty() else Global.DEFAULT_SERVER_IP)
