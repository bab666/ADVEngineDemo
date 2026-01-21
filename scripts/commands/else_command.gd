# D:\Works\Godot\ADVEngineDemo\scripts\commands\else_command.gd
extends BaseCommand
class_name ElseCommand

func get_command_name() -> String:
	return "else"

func execute(params: Dictionary, context: Dictionary) -> void:
	# @else は特に処理不要（到達した時点で実行される）
	pass

func requires_wait() -> bool:
	return false
