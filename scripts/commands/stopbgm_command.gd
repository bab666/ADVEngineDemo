# D:\Works\Godot\spelLDemo\scripts\commands\stopbgm_command.gd
extends BaseCommand
class_name StopBgmCommand

func get_command_name() -> String:
	return "stopbgm"

func get_description() -> String:
	return "BGMを停止します。パラメータ: file(省略可), time(フェード時間)"

func execute(params: Dictionary, _context: Dictionary) -> void:
	var file_name = params.get("file", "")
	var fade_time = params.get("time", 0.0)
	
	print("BGM停止: ", file_name if file_name != "" else "(現在のBGM)", " フェード時間: ", fade_time)
	
	if file_name != "":
		AudioManager.stop_bgm_by_name(file_name, fade_time)
	else:
		AudioManager.stop_bgm(fade_time)

func requires_wait() -> bool:
	return false
