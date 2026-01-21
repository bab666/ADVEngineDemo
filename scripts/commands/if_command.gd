# D:\Works\Godot\ADVEngineDemo\scripts\commands\if_command.gd
extends BaseCommand
class_name IfCommand

func get_command_name() -> String:
	return "if"

func execute(params: Dictionary, context: Dictionary) -> void:
	var condition: String = params.get("args", "")
	
	if condition.is_empty():
		push_error("@if: 条件が必要です")
		return
	
	# 条件を評価
	var result: bool = VariableManager.evaluate_expression(condition)
	
	print("条件分岐: %s = %s" % [condition, result])
	
	# 結果に応じて分岐を処理
	if result:
		# 条件が真の場合、次の行から実行を継続
		pass
	else:
		# 条件が偽の場合、@elif, @else, @endif を探す
		var scenario_manager = context.get("scenario_manager")
		if scenario_manager:
			_skip_to_next_branch(scenario_manager)

func requires_wait() -> bool:
	return false

## 次の分岐または終了までスキップ
static func _skip_to_next_branch(scenario_manager) -> void:
	var depth: int = 1  # ネスト深度
	var current_line: int = scenario_manager.current_line
	
	while current_line < scenario_manager.current_scenario.size() - 1:
		current_line += 1
		var command: Dictionary = scenario_manager.current_scenario[current_line]
		var cmd_type: String = command.get("type", "")
		
		# @if が見つかったらネスト深度を増やす
		if cmd_type == "if":
			depth += 1
		# @endif が見つかったら深度を減らす
		elif cmd_type == "endif":
			depth -= 1
			if depth == 0:
				# 対応する @endif に到達
				scenario_manager.current_line = current_line
				return
		# 同じ深度の @elif または @else が見つかった
		elif depth == 1 and (cmd_type == "elif" or cmd_type == "else"):
			# @elif の場合は条件を評価
			if cmd_type == "elif":
				scenario_manager.current_line = current_line - 1
				return
			# @else の場合はそのまま実行
			elif cmd_type == "else":
				scenario_manager.current_line = current_line
				return
	
	push_error("@if: 対応する @endif が見つかりません")
