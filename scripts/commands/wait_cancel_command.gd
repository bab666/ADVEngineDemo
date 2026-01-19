extends BaseCommand
class_name WaitCancelCommand

func get_command_name() -> String:
	return "wait_cancel"

func get_description() -> String:
	return "実行中のwaitを強制的にキャンセルします。"

func execute(params: Dictionary, context: Dictionary) -> void:
	context.game_manager.cancel_wait()

func requires_wait() -> bool:
	return false # このコマンド自体は待機しない
