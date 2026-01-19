# D:\Works\Godot\spelLDemo\scripts\commands\chara_hide_command.gd
extends BaseCommand
class_name CharaHideCommand

func get_command_name() -> String:
	return "chara_hide"

func get_description() -> String:
	return "キャラクター立ち絵を非表示にします。パラメータ: ID"

func execute(params: Dictionary, context: Dictionary) -> void:
	var char_id = params.get("id", "")
	
	if char_id.is_empty():
		push_warning("キャラクターIDが指定されていません")
		return
	
	var character_display = context.get("character_display")
	if not character_display:
		push_error("CharacterDisplay が見つかりません")
		return
	
	character_display.hide_character(char_id)
	print("キャラクター非表示: ", char_id)

func requires_wait() -> bool:
	return false
