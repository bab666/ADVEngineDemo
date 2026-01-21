# D:\Works\Godot\ADVEngineDemo\scripts\variable_manager.gd
extends Node

## 変数管理システム
## 
## システム変数とセーブデータ変数の2種類を管理
## - システム変数: user://settings.cfg に保存（全セーブデータ共通）
## - セーブ変数: セーブデータごとに保存

signal variable_changed(var_name: String, new_value: Variant)

# システム変数（全セーブデータ共通、設定など）
var system_vars: Dictionary = {}

# セーブ変数（セーブデータごと、フラグ・進行状況など）
var save_vars: Dictionary = {}

# 変数の型定義
enum VarType {
	INT,      # 整数
	FLOAT,    # 浮動小数点数
	STRING,   # 文字列
	BOOL      # 真偽値
}

func _ready() -> void:
	_load_system_variables()
	_initialize_default_variables()

## デフォルト変数を初期化
func _initialize_default_variables() -> void:
	# システム変数のデフォルト値
	if not system_vars.has("language"):
		system_vars["language"] = "ja"
	
	if not system_vars.has("play_count"):
		system_vars["play_count"] = 0
	
	# セーブ変数のデフォルト値（新規ゲーム時）
	# これらは reset_save_variables() で初期化される

## システム変数をファイルから読み込む
func _load_system_variables() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load("user://system_variables.cfg")
	
	if err == OK:
		for key in config.get_section_keys("variables"):
			system_vars[key] = config.get_value("variables", key)

## システム変数をファイルに保存
func _save_system_variables() -> void:
	var config: ConfigFile = ConfigFile.new()
	
	for key in system_vars.keys():
		config.set_value("variables", key, system_vars[key])
	
	config.save("user://system_variables.cfg")

## セーブ変数を初期化（新規ゲーム開始時）
func reset_save_variables() -> void:
	save_vars.clear()
	
	# デフォルト値を設定
	save_vars["player_name"] = "主人公"
	save_vars["chapter"] = 1
	save_vars["scene_count"] = 0
	save_vars["choice_count"] = 0
	
	# フラグ系
	save_vars["met_alice"] = false
	save_vars["event_flag_001"] = false
	save_vars["route"] = ""

## 変数を設定（自動型判定）
## 
## 例:
## - set_variable("count", 10)
## - set_variable("flag", true)
## - set_variable("name", "Alice")
func set_variable(var_name: String, value: Variant, is_system: bool = false) -> void:
	var target_dict: Dictionary = save_vars if not is_system else system_vars
	
	# 型変換処理
	var converted_value: Variant = _convert_value(value)
	
	target_dict[var_name] = converted_value
	variable_changed.emit(var_name, converted_value)
	
	# システム変数の場合は即座に保存
	if is_system:
		_save_system_variables()

## 変数を取得
func get_variable(var_name: String, is_system: bool = false) -> Variant:
	var target_dict: Dictionary = save_vars if not is_system else system_vars
	
	if target_dict.has(var_name):
		return target_dict[var_name]
	
	# 変数が存在しない場合は null を返す
	push_warning("変数が存在しません: " + var_name)
	return null

## 変数が存在するかチェック
func has_variable(var_name: String, is_system: bool = false) -> bool:
	var target_dict: Dictionary = save_vars if not is_system else system_vars
	return target_dict.has(var_name)

## 変数を削除
func remove_variable(var_name: String, is_system: bool = false) -> void:
	var target_dict: Dictionary = save_vars if not is_system else system_vars
	
	if target_dict.has(var_name):
		target_dict.erase(var_name)
		
		if is_system:
			_save_system_variables()

## 値を適切な型に変換
func _convert_value(value: Variant) -> Variant:
	# 既に適切な型の場合はそのまま返す
	if value is int or value is float or value is bool:
		return value
	
	# 文字列の場合は型推測を試みる
	if value is String:
		var str_value: String = value.strip_edges()
		
		# 真偽値
		if str_value.to_lower() == "true":
			return true
		elif str_value.to_lower() == "false":
			return false
		
		# 数値（整数）
		if str_value.is_valid_int():
			return str_value.to_int()
		
		# 数値（浮動小数点）
		if str_value.is_valid_float():
			return str_value.to_float()
		
		# それ以外は文字列として扱う
		return str_value
	
	return value

## 式を評価（条件分岐用）
## 
## サポートされる演算子:
## - 比較: ==, !=, >, <, >=, <=
## - 論理: and, or, not
## - 算術: +, -, *, /, %
## 
## 例:
## - evaluate_expression("count > 10")
## - evaluate_expression("flag == true")
## - evaluate_expression("name == 'Alice' and met_alice == true")
func evaluate_expression(expression: String) -> bool:
	var expr: String = expression.strip_edges()
	
	# 論理演算子で分割
	if " or " in expr:
		var parts: PackedStringArray = expr.split(" or ", false)
		for part in parts:
			if evaluate_expression(part.strip_edges()):
				return true
		return false
	
	if " and " in expr:
		var parts: PackedStringArray = expr.split(" and ", false)
		for part in parts:
			if not evaluate_expression(part.strip_edges()):
				return false
		return true
	
	# not 演算子
	if expr.begins_with("not "):
		return not evaluate_expression(expr.substr(4).strip_edges())
	
	# 比較演算子
	var operators: Array[String] = ["==", "!=", ">=", "<=", ">", "<"]
	
	for op in operators:
		if op in expr:
			var parts: PackedStringArray = expr.split(op, false, 1)
			if parts.size() == 2:
				var left: Variant = _evaluate_operand(parts[0].strip_edges())
				var right: Variant = _evaluate_operand(parts[1].strip_edges())
				
				match op:
					"==":
						return left == right
					"!=":
						return left != right
					">":
						return left > right
					"<":
						return left < right
					">=":
						return left >= right
					"<=":
						return left <= right
	
	# 単一の変数や値（真偽値として評価）
	var value: Variant = _evaluate_operand(expr)
	if value is bool:
		return value
	elif value is int or value is float:
		return value != 0
	elif value is String:
		return not value.is_empty()
	
	return false

## オペランド（変数または値）を評価
func _evaluate_operand(operand: String) -> Variant:
	var op: String = operand.strip_edges()
	
	# クォートで囲まれた文字列
	if (op.begins_with("'") and op.ends_with("'")) or (op.begins_with('"') and op.ends_with('"')):
		return op.substr(1, op.length() - 2)
	
	# 真偽値
	if op.to_lower() == "true":
		return true
	elif op.to_lower() == "false":
		return false
	
	# 数値
	if op.is_valid_int():
		return op.to_int()
	elif op.is_valid_float():
		return op.to_float()
	
	# 変数参照（$ または s$ プレフィックス）
	if op.begins_with("$"):
		var var_name: String = op.substr(1)
		return get_variable(var_name, false)
	elif op.begins_with("s$"):
		var var_name: String = op.substr(2)
		return get_variable(var_name, true)
	
	# プレフィックスなしの場合はセーブ変数として扱う
	if has_variable(op, false):
		return get_variable(op, false)
	elif has_variable(op, true):
		return get_variable(op, true)
	
	# それ以外は文字列リテラルとして扱う
	return op

## セーブデータをDictionaryとして取得
func get_save_data() -> Dictionary:
	return save_vars.duplicate(true)

## セーブデータを読み込み
func load_save_data(data: Dictionary) -> void:
	save_vars = data.duplicate(true)

## 変数の一覧を取得（デバッグ用）
func get_all_variables(is_system: bool = false) -> Dictionary:
	var target_dict: Dictionary = save_vars if not is_system else system_vars
	return target_dict.duplicate()

## 変数をインクリメント
func increment(var_name: String, amount: int = 1, is_system: bool = false) -> void:
	var current: Variant = get_variable(var_name, is_system)
	if current is int:
		set_variable(var_name, current + amount, is_system)
	elif current is float:
		set_variable(var_name, current + float(amount), is_system)
	else:
		push_warning("インクリメントできない型です: " + var_name)

## 変数をデクリメント
func decrement(var_name: String, amount: int = 1, is_system: bool = false) -> void:
	increment(var_name, -amount, is_system)

## 算術演算を実行
func calculate(var_name: String, operator: String, value: Variant, is_system: bool = false) -> void:
	var current: Variant = get_variable(var_name, is_system)
	var result: Variant
	
	match operator:
		"+":
			result = current + value
		"-":
			result = current - value
		"*":
			result = current * value
		"/":
			if value != 0:
				result = current / value
			else:
				push_error("ゼロ除算エラー")
				return
		"%":
			result = current % value
		_:
			push_warning("未対応の演算子: " + operator)
			return
	
	set_variable(var_name, result, is_system)
