# D:\Works\Godot\spelLDemo\scripts\commands\bgm_command.gd
extends BaseCommand
class_name BgmCommand

func get_command_name() -> String:
	return "bgm"

func get_description() -> String:
	return "BGMを再生します。volume, loop, seek, restart, sprite_time パラメータをサポート。"

func execute(params: Dictionary, _context: Dictionary) -> void:
	var file_name = params.get("file", "")
	if file_name.is_empty():
		push_warning("BGMファイル名が指定されていません")
		return
	
	print("BGM再生: ", file_name, " パラメータ: ", params)
	AudioManager.play_bgm_ex(file_name, params)

func requires_wait() -> bool:
	return false  # BGMは即座実行
