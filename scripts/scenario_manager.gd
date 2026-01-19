extends Node
class_name ScenarioManager

signal scenario_line_changed(command: Dictionary)
signal scenario_finished

var current_scenario: Array[Dictionary] = []
var current_line: int = -1
var current_file_path: String = ""
var labels: Dictionary = {}
var call_stack: Array = []
# ★追加: ブロック解析用
var is_recording_sequence: bool = false
var recorded_sequence: Array[Dictionary] = []
# ブロック解析用変数にID保持用を追加
var current_sequence_id: String = "" # ★追加

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
		if line.is_empty(): continue# ★ブロック開始判定
		if line.begins_with("@async"):
			is_recording_sequence = true
			recorded_sequence = []
			current_sequence_id = "" # リセット
			
			# id=... があるかチェック
			var parts = line.split(" ", false)
			for part in parts:
				if part.begins_with("id="):
					current_sequence_id = part.substr(3)
			continue
		
		# ★ブロック終了判定
		if line == "@end_async":
			is_recording_sequence = false
			var seq_cmd = {
				"type": "run_sequence",
				"commands": recorded_sequence.duplicate(),
				"id": current_sequence_id # ★IDをコマンドに含める
			}
			current_scenario.append(seq_cmd)
			recorded_sequence = []
			continue
			
		# ▼▼▼【修正】ここに追加してください ▼▼▼
		# ブロック内なら記録用配列に追加して、下のメイン追加処理をスキップする
		if is_recording_sequence:
			 # コメント行などは _parse_line が空を返すので無視される
			var cmd_data = _parse_line(line)
			if not cmd_data.is_empty():
				recorded_sequence.append(cmd_data)
			continue
		# ▲▲▲【修正】ここまで ▲▲▲	
		# ラベル解析処理
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
		"camera": return _parse_camera_command(parts)
		"sync": return {"type": "sync"}
	
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
	
# ★追加: カメラコマンド解析
# ★追加・修正: カメラコマンド解析
func _parse_camera_command(parts: Array) -> Dictionary:
	var result = {
		"type": "camera",
		# 初期値は null にしておき、コマンド側で「指定がなければ現在値を維持」などの判断をさせる余地を残すか、
		# あるいは明示的なデフォルト値を持たせるかは設計次第ですが、
		# ここでは既存に合わせてデフォルト値を設定しつつ、キーの有無で判定できるようにします。
		"time": 1000,
		"wait": false,
		"lazy": false,
		# offset, zoom, rotation は指定があった場合のみ辞書に入れる形が理想ですが、
		# 既存コードとの兼ね合いで、まずはデフォルト値をセットしておきます。
		# (コマンド側で params.has("key") で判定すれば、値の維持も実装可能です)
		"offset": Vector2.ZERO,
		"zoom": 1.0,
		"rotation": 0.0 
	}
	
	# 指定されたパラメータを記録するセット（デフォルト値による上書き防止用）
	var specified_params = []
	
	for i in range(1, parts.size()):
		var param = parts[i]
		
		# "offset:0,0" 形式
		if param.begins_with("offset:"):
			var val = param.substr(7).split(",")
			if val.size() >= 2:
				result["offset"] = Vector2(float(val[0]), float(val[1]))
				specified_params.append("offset")
		
		# "zoom:1.0" 形式
		elif param.begins_with("zoom:"):
			result["zoom"] = float(param.substr(5))
			specified_params.append("zoom")
			
		# ★追加: "rotation:45" 形式
		elif param.begins_with("rotation:"):
			result["rotation"] = float(param.substr(9))
			specified_params.append("rotation")
		
		# "time:3000" 形式
		elif param.begins_with("time:"):
			var val_str = param.substr(5)
			if val_str.is_valid_int():
				result["time"] = int(val_str)
			elif val_str.is_valid_float():
				result["time"] = int(float(val_str))
		
		# "time=3000" 形式
		elif param.begins_with("time="):
			var val_str = param.substr(5)
			if val_str.is_valid_int():
				result["time"] = int(val_str)
				
		elif param == "wait!":
			result["wait"] = true
		
		# ★追加: "lazy" フラグ
		elif param == "lazy":
			result["lazy"] = true
	
	# 指定されなかったパラメータについては、コマンド側で「変更なし」と扱えるよう
	# 辞書から削除する（＝null扱いにする）のが安全ですが、
	# 既存動作（offset, zoomの強制上書き）を維持するかどうかの判断が必要です。
	# 今回は「指定があったものだけキーに残す」方式に微修正して、
	# CameraCommand側で「キーがなければ現在の値を維持」できるようにします。
	
	if not "offset" in specified_params: result.erase("offset")
	if not "zoom" in specified_params: result.erase("zoom")
	if not "rotation" in specified_params: result.erase("rotation")
			
	return result

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
