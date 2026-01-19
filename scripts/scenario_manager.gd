# D:\Works\Godot\spelLDemo\scripts\scenario_manager.gd
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
			return {
				"type": "chara",
				"id": parts[1] if parts.size() > 1 else "",
				"expression": parts[2] if parts.size() > 2 else "",
				"x": int(parts[3]) if parts.size() > 3 else 0,
				"y": int(parts[4]) if parts.size() > 4 else 0
			}
		"chara_hide":
			return {"type": "chara_hide", "id": parts[1] if parts.size() > 1 else ""}
		"bgm":
			return _parse_bgm_command(parts)
		"stopbgm":
			return _parse_stop_command(parts, "bgm")
		"stopse":
			return _parse_stop_command(parts, "se")
	return {}

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
	
	# パラメータをパース (key=value 形式)
	for i in range(2, parts.size()):
		var param = parts[i]
		if "=" in param:
			var kv = param.split("=", true, 1)
			var key = kv[0].strip_edges()
			var value = kv[1].strip_edges()
			
			match key:
				"volume":
					result["volume"] = int(value)
				"sprite_time":
					result["sprite_time"] = value
				"loop":
					result["loop"] = value.to_lower() == "true"
				"seek":
					result["seek"] = float(value)
				"restart":
					result["restart"] = value.to_lower() == "true"
	
	return result

func _parse_stop_command(parts: Array, audio_type: String) -> Dictionary:
	var result = {
		"type": "stop" + audio_type,
		"file": "",
		"time": 0.0
	}
	
	# 第一引数がファイル名か time: か判定
	if parts.size() > 1:
		if parts[1].begins_with("time:"):
			# time:のみ指定されている場合
			var time_str = parts[1].substr(5).strip_edges()
			result["time"] = float(time_str)
		else:
			# ファイル名が指定されている
			result["file"] = parts[1]
			
			# time: パラメータを探す
			for i in range(2, parts.size()):
				if parts[i].begins_with("time:"):
					var time_str = parts[i].substr(5).strip_edges()
					result["time"] = float(time_str)
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
