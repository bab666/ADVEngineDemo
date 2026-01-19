extends Node
class_name ScenarioManager

signal scenario_line_changed(command: Dictionary)
signal scenario_finished

var current_scenario: Array[Dictionary] = []
var current_line: int = -1

func load_scenario(file_path: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("シナリオファイルが開けません: " + file_path)
		return false
	
	current_scenario.clear()
	current_line = -1
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		
		var command = _parse_line(line)
		if command:
			current_scenario.append(command)
	
	file.close()
	return true

func _parse_line(line: String) -> Dictionary:
	if line.begins_with("@"):
		return _parse_command(line)
	elif ":" in line:
		return _parse_dialogue(line)
	return {}

func _parse_command(line: String) -> Dictionary:
	var parts = line.substr(1).split(" ", false)
	if parts.is_empty():
		return {}
	
	var cmd = parts[0]
	match cmd:
		"bg":
			return {"type": "bg", "image": parts[1] if parts.size() > 1 else ""}
		"chara":
			# ★修正: 専用の解析関数を使用
			return _parse_chara_command(parts)
		"chara_hide":
			return {"type": "chara_hide", "id": parts[1] if parts.size() > 1 else ""}
		"bgm":
			return _parse_bgm_command(parts)
		"stopbgm":
			return _parse_stop_command(parts, "bgm")
		"stopse":
			return _parse_stop_command(parts, "se")
	return {}

# ★新規追加: キャラクターコマンド解析
func _parse_chara_command(parts: Array) -> Dictionary:
	var result = {
		"type": "chara",
		"id": parts[1] if parts.size() > 1 else "",
		"expression": parts[2] if parts.size() > 2 else "",
		"pos_mode": "auto",
		"pos": Vector3.ZERO,
		"scale": null,
		"time": 1000,
		"layer": 1,
		"wait": true,
		"reflect": false,
		"source_id": "" # ★追加: データ元のID（指定がない場合は id と同じ）
	}
# 初期状態では source_id は id と同じにする
	result["source_id"] = result["id"]
	
	for i in range(3, parts.size()):
		var param = parts[i]
		
		if param.begins_with("pos:"):
			var val = param.substr(4)
			if val == "auto":
				result["pos_mode"] = "auto"
			else:
				result["pos_mode"] = "manual"
				var coords = val.split(",")
				result["pos"].x = float(coords[0]) if coords.size() > 0 else 0
				result["pos"].y = float(coords[1]) if coords.size() > 1 else 0
				result["pos"].z = float(coords[2]) if coords.size() > 2 else 0
		
		elif "=" in param:
			var kv = param.split("=", true, 1)
			var key = kv[0]
			var val = kv[1]
			
			match key:
				"src": result["source_id"] = val # ★追加: src=ai のように指定
				"scale": result["scale"] = float(val)
				"time": result["time"] = int(val)
				"layer": result["layer"] = int(val)
				"wait": result["wait"] = (val.to_lower() == "true")
				"reflect": result["reflect"] = (val.to_lower() == "true")
		
		# 互換性: 数値のみの場合は座標とみなす
		elif param.is_valid_float() or param.is_valid_int():
			result["pos_mode"] = "manual"
			if result["pos"].x == 0 and result["pos"].y == 0:
				result["pos"].x = float(param)
			elif result["pos"].y == 0:
				result["pos"].y = float(param)
	
	return result

func _parse_bgm_command(parts: Array) -> Dictionary:
	var result = {
		"type": "bgm",
		"file": parts[1] if parts.size() > 1 else "",
		"volume": 100,
		"sprite_time": "",
		"loop": true,
		"seek": 0.0,
		"restart": false
	}
	for i in range(2, parts.size()):
		var param = parts[i]
		if "=" in param:
			var kv = param.split("=", true, 1)
			var key = kv[0].strip_edges()
			var value = kv[1].strip_edges()
			match key:
				"volume": result["volume"] = int(value)
				"sprite_time": result["sprite_time"] = value
				"loop": result["loop"] = value.to_lower() == "true"
				"seek": result["seek"] = float(value)
				"restart": result["restart"] = value.to_lower() == "true"
	return result

func _parse_stop_command(parts: Array, audio_type: String) -> Dictionary:
	var result = {"type": "stop" + audio_type, "file": "", "time": 0.0}
	if parts.size() > 1:
		if parts[1].begins_with("time:"):
			result["time"] = float(parts[1].substr(5))
		else:
			result["file"] = parts[1]
			for i in range(2, parts.size()):
				if parts[i].begins_with("time:"):
					result["time"] = float(parts[i].substr(5))
					break
	return result

func _parse_dialogue(line: String) -> Dictionary:
	var parts = line.split(":", true, 1)
	return {
		"type": "dialogue",
		"character": parts[0].strip_edges(),
		"text": parts[1].strip_edges() if parts.size() > 1 else ""
	}

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
