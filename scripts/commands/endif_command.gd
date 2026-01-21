# D:\Works\Godot\ADVEngineDemo\scripts\commands\endif_command.gd
extends BaseCommand
class_name EndifCommand

func get_command_name() -> String:
	return "endif"

func execute(params: Dictionary, context: Dictionary) -> void:
	# @endif は終了マーカーとして機能するだけで、特に処理は不要
	pass

func requires_wait() -> bool:
	return false
