# D:\Works\Godot\spelLDemo\scripts\commands\chara_command.gd
extends BaseCommand
class_name CharaCommand

func get_command_name() -> String:
	return "chara"

func get_description() -> String:
	return "キャラクター立ち絵を表示します。パラメータ: ID, 表情, x座標, y座標"

func execute(params: Dictionary, context: Dictionary) -> void:
	var char_id = params.get("id", "")
	var expression = params.get("expression", "")
	var x = params.get("x", 0)
	var y = params.get("y", 0)
	
	if char_id.is_empty():
		push_warning("キャラクターIDが指定されていません")
		return
	
	var character_display = context.get("character_display")
	if not character_display:
		push_error("CharacterDisplay が見つかりません")
		return
	
	character_display.show_character(char_id, expression, x, y)
	print("キャラクター表示: ", char_id, " ", expression, " (", x, ", ", y, ")")

func requires_wait() -> bool:
	return false
