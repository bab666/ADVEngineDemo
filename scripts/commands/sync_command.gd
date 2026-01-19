extends BaseCommand
class_name SyncCommand

func get_command_name() -> String:
	return "sync"

func execute(_params: Dictionary, context: Dictionary) -> void:
	var gm = context.get("game_manager")
	if gm:
		gm.set_scenario_paused(true)
		await gm.wait_active_tasks() # タスク完了待ち
		gm.set_scenario_paused(false)
		
		if context.scenario_manager.has_next():
			context.scenario_manager.next_line()

func requires_wait() -> bool:
	return true
