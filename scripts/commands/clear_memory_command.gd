extends BaseCommand
class_name ClearMemoryCommand

func get_command_name() -> String:
	return "clear_memory"

func get_description() -> String:
	return "未使用のキャラクターデータや画像をメモリから解放します。章の変わり目などに使用してください。"

func execute(_params: Dictionary, context: Dictionary) -> void:
	var gm = context.get("game_manager")
	if gm:
		gm.clear_unused_resources()

func requires_wait() -> bool:
	return false
