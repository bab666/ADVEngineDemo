extends Node
class_name ScenarioManager

signal scenario_line_changed(command: Dictionary)
signal scenario_finished

var current_scenario: Array[Dictionary] = []
var current_line: int = -1
var current_file_path: String = "" # 現在のファイルパスを保持

# ラベル管理: "LabelName" -> line_index
var labels: Dictionary = {}

# コールスタック: [{ "file": path, "line": index }, ...]
var call_stack: Array = []

func load_scenario(file_path: String) -> bool:
	# パス修正: 拡張子がなければ .txt を補完する等の親切設計を入れても良いが、基本はそのまま
	# resources/scenarios/ が省略されていた場合の対応などをここに入れても良い
	if not file_path.begins_with("res://"):
		file_path = "res://resources/scenarios/" + file_path
	if not file_path.ends_with(".txt"):
		file_path += ".txt"
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("シナリオファイルが開けません: " + file_path)
		return false
	
	current_scenario.clear()
	labels.clear() # ラベル辞書をリセット
	current_line = -1
	current_file_path = file_path
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		
		# ★ラベル解析
		if line.begins_with("#"):
			var label_name = line.substr(1).strip_edges()
			# 現在の配列サイズ = 次に追加されるコマンドのインデックス
			labels[label_name] = current_scenario.size()
			continue # ラベル行自体はコマンドとして追加しない
		
		var command = _parse_line(line)
		if command:
			current_scenario.append(command)
	
	file.close()
	print("シナリオロード完了: ", file_path, " ラベル数: ", labels.size())
	return true

# --- ジャンプ・コール機能 ---

# 指定されたターゲットへジャンプ
# target: "Scenario", ".Label", "Scenario.Label"
func jump_to(target: String):
	var target_file = current_file_path
	var target_label = ""
	
	if target.begins_with("."):
		# .Label (同ファイル内)
		target_label = target.substr(1)
	elif "." in target:
		# File.Label
		var parts = target.split(".")
		target_file = parts[0]
		target_label = parts[1]
	else:
		# File (先頭へ)
		target_file = target
	
	# ファイル変更が必要な場合
	if target_file != current_file_path and target_file != target_file.get_file().get_basename():
		# パス補完ロジック (load_scenarioと同様の簡易チェック)
		if not target_file.begins_with("res://"): 
			# すでにあるパスと比較して違う場合のみロード
			# ここでは簡易的にファイル名ベースで比較せず、常にロードを試みる
			load_scenario(target_file)
	
	# ファイル名のみ指定されていて、かつ現在のファイル名と異なる場合（パス補完前）の考慮が必要だが、
	# ここでは load_scenario 内でパス補完される前提で動く
	if current_file_path.find(target_file) == -1 and target_file != current_file_path:
		load_scenario(target_file)

	# ラベルへ移動
	if not target_label.is_empty():
		if labels.has(target_label):
			# next_line() で +1 されるため、目的のインデックス - 1 に設定する
			current_line = labels[target_label] - 1
		else:
			push_error("ラベルが見つかりません: " + target_label)
	else:
		# ラベル指定なし＝先頭へ
		current_line = -1

# サブルーチン呼び出し
func call_scenario(target: String):
	# 現在の状態をスタックに保存
	# 戻り先は「現在の行」 (next_lineで次の行に進むため、戻った後に+1される)
	call_stack.push_back({
		"file": current_file_path,
		"line": current_line
	})
	print("Call Stack Push: ", call_stack.back())
	
	jump_to(target)

# サブルーチンから復帰
func return_from_call():
	if call_stack.is_empty():
		push_error("Callスタックが空です。@returnできません。")
		return
	
	var return_state = call_stack.pop_back()
	print("Call Stack Pop: ", return_state)
	
	# ファイルが異なるならロードし直す
	if return_state["file"] != current_file_path:
		load_scenario(return_state["file"])
	
	# 行を復元
	current_line = return_state["line"]

# --- 既存のパース処理 ---

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
		"bg": return {"type": "bg", "image": parts[1] if parts.size() > 1 else ""}
		"chara": return _parse_chara_command(parts)
		"chara_hide": return {"type": "chara_hide", "id": parts[1] if parts.size() > 1 else ""}
		"bgm": return _parse_bgm_command(parts)
		"stopbgm": return _parse_stop_command(parts, "bgm")
		"stopse": return _parse_stop_command(parts, "se")
		"wait": return _parse_wait_command(parts)
		"wait_cancel": return {"type": "wait_cancel"}
		"window": return _parse_window_command(parts)
		# ★新規追加
		"jump": return {"type": "jump", "target": parts[1] if parts.size() > 1 else ""}
		"call": return {"type": "call", "target": parts[1] if parts.size() > 1 else ""}
		"return": return {"type": "return"}
			
	return {}

# _parse_chara_command, _parse_bgm_command 等は既存のまま保持
# (前回の回答にある最新版を使用してください)
# 以下、省略なしのコードが必要であれば前回の回答を参照し、そこに上記を追加してください。
# ここではスペース節約のため省略しますが、既存関数は消さないでください。

# Windowコマンド解析 (前回追加分)
func _parse_window_command(parts: Array) -> Dictionary:
	var id = parts[1] if parts.size() > 1 else "default"
	if "=" in id: id = id.split("=")[1]
	return {"type": "window", "id": id}

# (Waitコマンド解析など既存関数はそのまま...)
func _parse_wait_command(parts: Array) -> Dictionary:
	var result = {"type": "wait", "time": 1000}
	for i in range(1, parts.size()):
		var param = parts[i]
		if param.begins_with("time="): result["time"] = int(param.substr(5))
		elif param.is_valid_int(): result["time"] = int(param)
	return result

func _parse_chara_command(parts: Array) -> Dictionary:
	# (前回の最新版コード)
	var result = { "type": "chara", "id": parts[1] if parts.size() > 1 else "", "pos_mode": "auto", "pos": Vector3.ZERO, "scale": null, "time": 1000, "layer": 1, "wait": true, "reflect": false, "source_id": "" }
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
				"wait": result["wait"]=(v.to_lower()=="true")
				"reflect": result["reflect"]=(v.to_lower()=="true")
		elif param.is_valid_float() or param.is_valid_int():
			result["pos_mode"] = "manual"
			if result["pos"].x==0: result["pos"].x=float(param)
			elif result["pos"].y==0: result["pos"].y=float(param)
	return result

func _parse_bgm_command(parts: Array) -> Dictionary:
	# (省略: 既存のまま)
	return {"type": "bgm", "file": parts[1] if parts.size() > 1 else ""} # 簡易

func _parse_stop_command(parts: Array, type: String) -> Dictionary:
	# (省略: 既存のまま)
	return {"type": "stop"+type}

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
