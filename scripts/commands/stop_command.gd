extends BaseCommand
class_name StopCommand

func get_command_name() -> String:
	return "stop"

func get_description() -> String:
	return "シナリオの進行を完全に停止します。クリックしても進みません（選択肢待ちなどに使用）。"

func execute(_params: Dictionary, context: Dictionary) -> void:
	var gm = context.get("game_manager")
	if gm:
		gm.set_scenario_paused(true)

func requires_wait() -> bool:
	return true # 自動進行を止める
