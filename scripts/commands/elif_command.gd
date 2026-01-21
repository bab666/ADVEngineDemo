# D:\Works\Godot\ADVEngineDemo\scripts\commands\elif_command.gd
extends BaseCommand
class_name ElifCommand

func get_command_name() -> String:
	return "elif"

func execute(params: Dictionary, context: Dictionary) -> void:
	var condition: String = params.get("args", "")
	
	if condition.is_empty():
		push_error("@elif: 条件が必要です")
		return
	
	# 条件を評価
	var result: bool = VariableManager.evaluate_expression(condition)
	
	print("elif条件分岐: %s = %s" % [condition, result])
	
	if result:
		# 条件が真の場合、次の行から実行を継続
		pass
	else:
		# 条件が偽の場合、次の @elif, @else, @endif を探す
		var scenario_manager = context.get("scenario_manager")
		if scenario_manager:
			IfCommand._skip_to_next_branch(scenario_manager)

func requires_wait() -> bool:
	return false
