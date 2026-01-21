# D:\Works\Godot\ADVEngineDemo\scripts\commands\set_command.gd
extends BaseCommand
class_name SetCommand

func get_command_name() -> String:
	return "set"

func execute(params: Dictionary, context: Dictionary) -> void:
	var args: String = params.get("args", "")
	
	if args.is_empty():
		push_error("@set: 引数が必要です")
		return
	
	# = で分割
	if not "=" in args:
		push_error("@set: = が必要です (例: @set count=10)")
		return
	
	var parts: PackedStringArray = args.split("=", false, 1)
	if parts.size() != 2:
		push_error("@set: 不正な形式です")
		return
	
	var var_name: String = parts[0].strip_edges()
	var value_str: String = parts[1].strip_edges()
	
	# システム変数かチェック（s$ プレフィックス）
	var is_system: bool = false
	if var_name.begins_with("s$"):
		is_system = true
		var_name = var_name.substr(2)
	elif var_name.begins_with("$"):
		var_name = var_name.substr(1)
	
	# 値を変換
	var value: Variant = _parse_value(value_str)
	
	# 変数を設定
	VariableManager.set_variable(var_name, value, is_system)
	
	print("変数設定: %s = %s (system=%s)" % [var_name, value, is_system])

## 値をパース
func _parse_value(value_str: String) -> Variant:
	var val: String = value_str.strip_edges()
	
	# クォートで囲まれた文字列
	if (val.begins_with("'") and val.ends_with("'")) or (val.begins_with('"') and val.ends_with('"')):
		return val.substr(1, val.length() - 2)
	
	# 真偽値
	if val.to_lower() == "true":
		return true
	elif val.to_lower() == "false":
		return false
	
	# 数値
	if val.is_valid_int():
		return val.to_int()
	elif val.is_valid_float():
		return val.to_float()
	
	# 変数参照
	if val.begins_with("$"):
		var var_name: String = val.substr(1)
		var is_system: bool = false
		
		if var_name.begins_with("s$"):
			is_system = true
			var_name = var_name.substr(2)
		
		return VariableManager.get_variable(var_name, is_system)
	
	# 算術式の評価（簡易版）
	if "+" in val or "-" in val or "*" in val or "/" in val:
		return _evaluate_arithmetic(val)
	
	# それ以外は文字列として扱う
	return val

## 簡易的な算術式評価
func _evaluate_arithmetic(expression: String) -> Variant:
	var expr: Expression = Expression.new()
	var error: Error = expr.parse(expression)
	
	if error != OK:
		push_error("算術式の解析エラー: " + expression)
		return 0
	
	var result: Variant = expr.execute()
	
	if expr.has_execute_failed():
		push_error("算術式の実行エラー: " + expression)
		return 0
	
	return result

func requires_wait() -> bool:
	return false
