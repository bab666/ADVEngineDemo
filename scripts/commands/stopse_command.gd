# D:\Works\Godot\spelLDemo\scripts\commands\stopse_command.gd
extends BaseCommand
class_name StopSeCommand

func get_command_name() -> String:
	return "stopse"

func get_description() -> String:
	return "SEを停止します。パラメータ: file(省略可), time(フェード時間)"

func execute(params: Dictionary, context: Dictionary) -> void:
	var file_name = params.get("file", "")
	var fade_time = params.get("time", 0.0)
	
	print("SE停止: ", file_name if file_name != "" else "(全てのSE)", " フェード時間: ", fade_time)
	
	if file_name != "":
		AudioManager.stop_se_by_name(file_name, fade_time)
	else:
		AudioManager.stop_all_se(fade_time)

func requires_wait() -> bool:
	return false
