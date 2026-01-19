extends BaseCommand
class_name KillCommand

func get_command_name() -> String:
	return "kill"

func get_description() -> String:
	return "実行中の非同期タスク（演出）を強制終了します。パラメータ: id (省略時は全停止)"

func execute(params: Dictionary, context: Dictionary) -> void:
	var id = params.get("id", "")
	var gm = context.get("game_manager")
	if gm:
		gm.kill_active_tasks(id)

func requires_wait() -> bool:
	return false # 即座に次へ進む
