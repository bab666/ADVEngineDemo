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
	
	# CharacterDisplay経由で正式名称を取得
	var character_display = context.get("character_display")
	if character_display:
		var char_data = character_display.get_character_data(character_id)
		if char_data and not char_data.display_name.is_empty():
			display_name = char_data.display_name
	
	# ★修正: WindowManager経由で表示
	var window_manager = context.get("window_manager")
	if window_manager:
		# IDに基づいてウインドウを切り替えるロジックを入れるならここ
		# 例: ナレーターなら "narrator" ウインドウを使うなど
		# 現状はすべて "default" を使用
		var target_window = "default"
		
		# キャラクターデータに「使用するウインドウID」を持たせる拡張も可能
		
		window_manager.show_dialogue(target_window, display_name, text)
	else:
		push_error("WindowManager が見つかりません")

func requires_wait() -> bool:
	return true  # ユーザー入力待ち
