# D:\Works\Godot\spelLDemo\scripts\commands\bg_command.gd
extends BaseCommand
class_name BgCommand

func get_command_name() -> String:
	return "bg"

func get_description() -> String:
	return "背景画像を変更します。パラメータ: 画像名"

func execute(params: Dictionary, context: Dictionary) -> void:
	var image_name = params.get("image", "")
	if image_name.is_empty():
		push_warning("背景画像名が指定されていません")
		return
	
	var background = context.get("background")
	if not background:
		push_error("Background が見つかりません")
		return
	
	var texture_path = "res://resources/backgrounds/%s.png" % image_name
	if ResourceLoader.exists(texture_path):
		background.texture = load(texture_path)
		print("背景変更: ", image_name)
	else:
		push_warning("背景画像が見つかりません: " + texture_path)

func requires_wait() -> bool:
	return false
