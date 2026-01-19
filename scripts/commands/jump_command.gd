extends BaseCommand
class_name JumpCommand

func get_command_name() -> String:
	return "jump"

func get_description() -> String:
	return "指定したシナリオまたはラベルにジャンプします。パラメータ: ScenarioName, .LabelName, Scenario.Label"

func execute(params: Dictionary, context: Dictionary) -> void:
	var target = params.get("target", "")
	if target.is_empty():
		push_warning("@jump のターゲットが指定されていません")
		return
	
	var sm = context.get("scenario_manager")
	if sm:
		sm.jump_to(target)

func requires_wait() -> bool:
	# ジャンプした瞬間に次の行（ジャンプ先）を実行してほしいので false
	return false
