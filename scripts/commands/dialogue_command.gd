extends BaseCommand
class_name DialogueCommand

func get_command_name() -> String:
	return "dialogue"

func get_description() -> String:
	return "キャラクターの台詞を表示します。"

func execute(params: Dictionary, context: Dictionary) -> void:
	var character_id = params.get("character", "")
	var text = params.get("text", "")
	
	var display_name = character_id
	
	# CharacterDisplay経由で正式名称（Display Name）を取得
	var character_display = context.get("character_display")
	if character_display:
		# IDを使ってデータを検索
		var char_data = character_display.get_character_data(character_id)
		if char_data and not char_data.display_name.is_empty():
			display_name = char_data.display_name
	
	var message_window = context.get("message_window")
	if message_window:
		# IDではなく、取得した表示名を渡す
		message_window.show_dialogue(display_name, text)
	else:
		push_error("MessageWindow が見つかりません")

func requires_wait() -> bool:
	return true  # ユーザー入力待ち
