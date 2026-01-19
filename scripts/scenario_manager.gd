extends Node
class_name ScenarioManager

signal scenario_line_changed(command: Dictionary)
signal scenario_finished

var current_scenario: Array[Dictionary] = []
var current_line: int = -1
var current_file_path: String = ""
var labels: Dictionary = {}
var call_stack: Array = []

# (省略: load_scenario, jump_to, call_scenario, return_from_call は既存のまま変更なし)
func load_scenario(file_path: String) -> bool:
	if not file_path.begins_with("res://"):
		file_path = "res://resources/scenarios/" + file_path
	if not file_path.ends_with(".txt"):
		file_path += ".txt"
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null: return false
	current_scenario.clear(); labels.clear(); current_line = -1; current_file_path = file_path
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty(): continue
		if line.begins_with("#"):
			labels[line.substr(1).strip_edges()] = current_scenario.size()
			continue
		var command = _parse_line(line)
		if command: current_scenario.append(command)
	file.close()
	return true

func jump_to(target: String):
	# (前回の実装と同じため省略)
	var target_file = current_file_path
	var target_label = ""
	if target.begins_with("."): target_label = target.substr(1)
	elif "." in target:
		var parts = target.split(".")
		target_file = parts[0]; target_label = parts[1]
	else: target_file = target
	
	if current_file_path.find(target_file) == -1 and target_file != current_file_path:
		load_scenario(target_file)
	if not target_label.is_empty():
		if labels.has(target_label): current_line = labels[target_label] - 1
		else: push_error("ラベルなし: " + target_label)
	else: current_line = -1

func call_scenario(target: String):
	call_stack.push_back({ "file": current_file_path, "line": current_line })
	jump_to(target)

func return_from_call():
	if call_stack.is_empty(): return
	var state = call_stack.pop_back()
	if state["file"] != current_file_path: load_scenario(state["file"])
	current_line = state["line"]

# --- パース処理 ---

func _parse_line(line: String) -> Dictionary:
	if line.begins_with("@"):
		return _parse_command(line)
	elif ":" in line:
		return _parse_dialogue(line)
	return {}

# ★新規: 共通パラメータ解析ヘルパー
# 全てのコマンド辞書に対して、if, unless, wait パラメータを注入する
func _parse_common_params(result: Dictionary, parts: Array, start_index: int = 1):
	for i in range(start_index, parts.size()):
		var param = parts[i]
		if "=" in param:
			var kv = param.split("=", true, 1)
			var key = kv[0].strip_edges()
			var val = kv[1].strip_edges()
			
			match key:
				"if":
					result["if"] = val
				"unless":
					result["unless"] = val
				"wait":
					result["wait"] = (val.to_lower() == "true")

func _parse_command(line: String) -> Dictionary:
	var parts = line.substr(1).split(" ", false)
	if parts.is_empty(): return {}
	
	var cmd = parts[0]
	var result = {}
	
	match cmd:
		"bg":
			result = {"type": "bg", "image": parts[1] if parts.size() > 1 else ""}
		"chara":
			result = _parse_chara_command(parts)
		"chara_hide":
			result = {"type": "chara_hide", "id": parts[1] if parts.size() > 1 else ""}
		"bgm":
			result = _parse_bgm_command(parts)
		"stopbgm":
			result = _parse_stop_command(parts, "bgm")
		"stopse":
			result = _parse_stop_command(parts, "se")
		"wait":
			result = _parse_wait_command(parts)
		"wait_cancel":
			result = {"type": "wait_cancel"}
		"window":
			result = _parse_window_command(parts)
		"jump":
			result = {"type": "jump", "target": parts[1] if parts.size() > 1 else ""}
		"call":
			result = {"type": "call", "target": parts[1] if parts.size() > 1 else ""}
		"return":
			result = {"type": "return"}
		"stop":
			result = {"type": "stop"}
	
	# ★重要: 全コマンドの最後に共通パラメータ解析を実行
	if not result.is_empty():
		_parse_common_params(result, parts)
		
	return result

# 個別解析関数 (既存ロジック + 共通解析は _parse_command で一括適用されるため、ここでは固有部分のみで良いが
# 既存のパラメーターとかぶらないように注意)

func _parse_chara_command(parts: Array) -> Dictionary:
	var result = {
		"type": "chara",
		"id": parts[1] if parts.size() > 1 else "",
		"expression": parts[2] if parts.size() > 2 else "",
		"source_id": "", "pos_mode": "auto", "pos": Vector3.ZERO, "scale": null, "time": 1000, "layer": 1, "reflect": false,
		# waitは共通処理で上書きされるが、デフォルト値として持っておく
		"wait": true 
	}
	result["source_id"] = result["id"]
	for i in range(3, parts.size()):
		var param = parts[i]
		if param.begins_with("pos:"):
			var val = param.substr(4)
			if val == "auto": result["pos_mode"] = "auto"
			else:
				result["pos_mode"] = "manual"
				var coords = val.split(",")
				result["pos"].x = float(coords[0]) if coords.size() > 0 else 0.0
				result["pos"].y = float(coords[1]) if coords.size() > 1 else 0.0
		elif "=" in param:
			var kv = param.split("=", true, 1); var k=kv[0]; var v=kv[1]
			match k:
				"src": result["source_id"]=v
				"scale": result["scale"]=float(v)
				"time": result["time"]=int(v)
				"layer": result["layer"]=int(v)
				"reflect": result["reflect"]=(v.to_lower()=="true")
				# wait, if, unless は _parse_common_params で処理されるためここではスキップしても良いが
				# 明示的に書いてあっても後勝ちで上書きされるので問題ない
		elif param.is_valid_float() or param.is_valid_int():
			result["pos_mode"] = "manual"
			if result["pos"].x==0: result["pos"].x=float(param)
			elif result["pos"].y==0: result["pos"].y=float(param)
	return result

func _parse_wait_command(parts: Array) -> Dictionary:
	var result = {"type": "wait", "time": 1000}
	for i in range(1, parts.size()):
		var param = parts[i]
		if param.begins_with("time="): result["time"] = int(param.substr(5))
		elif param.is_valid_int(): result["time"] = int(param)
	return result

func _parse_bgm_command(parts: Array) -> Dictionary:
	var result = {"type": "bgm", "file": parts[1] if parts.size() > 1 else "", "volume": 100, "sprite_time": "", "loop": true, "seek": 0.0, "restart": false}
	for i in range(2, parts.size()):
		var param = parts[i]
		if "=" in param:
			var kv = param.split("=", true, 1); var k=kv[0]; var v=kv[1]
			match k:
				"volume": result["volume"] = int(v)
				"sprite_time": result["sprite_time"] = v
				"loop": result["loop"] = (v.to_lower() == "true")
				"seek": result["seek"] = float(v)
				"restart": result["restart"] = (v.to_lower() == "true")
	return result

func _parse_stop_command(parts: Array, type: String) -> Dictionary:
	var result = {"type": "stop"+type, "file": "", "time": 0.0}
	if parts.size() > 1:
		if parts[1].begins_with("time:"): result["time"] = float(parts[1].substr(5))
		else:
			result["file"] = parts[1]
			for i in range(2, parts.size()):
				if parts[i].begins_with("time:"): result["time"] = float(parts[i].substr(5)); break
	return result

func _parse_window_command(parts: Array) -> Dictionary:
	var id = parts[1] if parts.size() > 1 else "default"
	if "=" in id: id = id.split("=")[1]
	return {"type": "window", "id": id}

func _parse_dialogue(line: String) -> Dictionary:
	var parts = line.split(":", true, 1)
	return {"type": "dialogue", "character": parts[0].strip_edges(), "text": parts[1].strip_edges() if parts.size() > 1 else ""}

func next_line() -> Dictionary:
	current_line += 1
	if current_line >= current_scenario.size():
		scenario_finished.emit()
		return {}
	var command = current_scenario[current_line]
	scenario_line_changed.emit(command)
	return command

func has_next() -> bool:
	return current_line < current_scenario.size() - 1
