extends BaseCommand
class_name CallCommand

func get_command_name() -> String:
	return "call"

func get_description() -> String:
	return "現在の位置を保存してジャンプします(@returnで戻れます)。パラメータ: Target"

func execute(params: Dictionary, context: Dictionary) -> void:
	var target = params.get("target", "")
	if target.is_empty():
		push_warning("@call のターゲットが指定されていません")
		return
	
	var sm = context.get("scenario_manager")
	if sm:
		sm.call_scenario(target)

func requires_wait() -> bool:
	return false
