# D:\Works\Godot\ADVEngineDemo\scripts\save_manager.gd
extends Node
class_name SaveManager

## セーブ・ロード管理システム
##
## 機能:
## - マルチスロット対応（通常セーブ + オートセーブ + クイックセーブ）
## - スナップショット方式（全システムの状態を保存）
## - サムネイル対応（将来実装）
## - メタデータ管理（日時、プレイ時間など）

signal save_completed(slot_id: int)
signal load_completed(slot_id: int)
signal save_failed(slot_id: int, error: String)
signal load_failed(slot_id: int, error: String)

const SAVE_DIR: String = "user://saves/"
const SAVE_FILE_EXTENSION: String = ".sav"
const SAVE_VERSION: String = "1.0.0"

const SLOT_AUTO_SAVE: int = 0
const SLOT_QUICK_SAVE: int = -1
const MAX_NORMAL_SLOTS: int = 99

# GameManagerへの参照
var game_manager: Node = null

# セーブスロット情報のキャッシュ
var slot_cache: Dictionary = {}

func _ready() -> void:
	_ensure_save_directory()
	_build_slot_cache()

## セーブディレクトリを確保
func _ensure_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		var err: Error = DirAccess.make_dir_recursive_absolute(SAVE_DIR)
		if err != OK:
			push_error("セーブディレクトリの作成に失敗: " + str(err))

## セーブファイルのパスを取得
func _get_save_path(slot_id: int) -> String:
	var filename: String
	
	if slot_id == SLOT_AUTO_SAVE:
		filename = "autosave"
	elif slot_id == SLOT_QUICK_SAVE:
		filename = "quicksave"
	else:
		filename = "save_%03d" % slot_id
	
	return SAVE_DIR + filename + SAVE_FILE_EXTENSION

## ゲームをセーブ
func save_game(slot_id: int) -> bool:
	if not game_manager:
		push_error("SaveManager: GameManagerが設定されていません")
		save_failed.emit(slot_id, "GameManager not set")
		return false
	
	# セーブデータを構築
	var save_data: Dictionary = _build_save_data()
	
	if save_data.is_empty():
		push_error("セーブデータの構築に失敗")
		save_failed.emit(slot_id, "Failed to build save data")
		return false
	
	# メタデータを追加
	save_data["metadata"] = _build_metadata(slot_id)
	
	# ファイルに書き込み
	var success: bool = _write_save_file(slot_id, save_data)
	
	if success:
		# キャッシュを更新
		_update_slot_cache(slot_id, save_data["metadata"])
		save_completed.emit(slot_id)
		print("セーブ完了: スロット %d" % slot_id)
	else:
		save_failed.emit(slot_id, "File write failed")
	
	return success

## ゲームをロード
func load_game(slot_id: int) -> bool:
	if not game_manager:
		push_error("SaveManager: GameManagerが設定されていません")
		load_failed.emit(slot_id, "GameManager not set")
		return false
	
	# セーブデータを読み込み
	var save_data: Dictionary = _read_save_file(slot_id)
	
	if save_data.is_empty():
		push_error("セーブデータの読み込みに失敗: スロット %d" % slot_id)
		load_failed.emit(slot_id, "Failed to read save data")
		return false
	
	# バージョンチェック
	var saved_version: String = save_data.get("version", "0.0.0")
	if not _is_compatible_version(saved_version):
		push_error("互換性のないセーブデータバージョン: %s" % saved_version)
		load_failed.emit(slot_id, "Incompatible version")
		return false
	
	# 状態を復元
	var success: bool = _restore_game_state(save_data)
	
	if success:
		load_completed.emit(slot_id)
		print("ロード完了: スロット %d" % slot_id)
	else:
		load_failed.emit(slot_id, "Failed to restore state")
	
	return success

## セーブデータを構築
func _build_save_data() -> Dictionary:
	var data: Dictionary = {}
	
	data["version"] = SAVE_VERSION
	data["engine_version"] = Engine.get_version_info()
	
	# 各システムの状態を収集
	if game_manager.has_node("ScenarioManager"):
		data["scenario"] = game_manager.scenario_manager.save_state()
	
	if game_manager.has_node("CharacterDisplay"):
		data["characters"] = game_manager.character_display.save_state()
	
	data["audio"] = AudioManager.save_state()
	data["variables"] = VariableManager.get_save_data()
	data["camera"] = _get_camera_state()
	
	# ウィンドウ状態（将来実装）
	# data["windows"] = game_manager.window_manager.save_state()
	
	return data

## メタデータを構築
func _build_metadata(slot_id: int) -> Dictionary:
	var metadata: Dictionary = {}
	
	metadata["slot_id"] = slot_id
	metadata["save_date"] = Time.get_datetime_string_from_system()
	metadata["timestamp"] = Time.get_unix_time_from_system()
	
	# シナリオ情報
	if game_manager.scenario_manager:
		metadata["scenario_file"] = game_manager.scenario_manager.current_file_path
		metadata["scenario_line"] = game_manager.scenario_manager.current_line
	
	# ゲーム進行情報（変数から取得）
	if VariableManager.has_variable("chapter"):
		metadata["chapter"] = VariableManager.get_variable("chapter")
	
	if VariableManager.has_variable("scene_count"):
		metadata["scene_count"] = VariableManager.get_variable("scene_count")
	
	# プレイ時間（将来実装）
	metadata["play_time"] = 0
	
	# サムネイル（将来実装）
	metadata["thumbnail"] = ""
	
	return metadata

## カメラ状態を取得
func _get_camera_state() -> Dictionary:
	if not game_manager.has_node("Camera2D"):
		return {}
	
	var camera: Camera2D = game_manager.get_node("Camera2D")
	
	return {
		"position": {"x": camera.position.x, "y": camera.position.y},
		"zoom": {"x": camera.zoom.x, "y": camera.zoom.y},
		"rotation": camera.rotation_degrees
	}

## カメラ状態を復元
func _restore_camera_state(data: Dictionary) -> void:
	if data.is_empty() or not game_manager.has_node("Camera2D"):
		return
	
	var camera: Camera2D = game_manager.get_node("Camera2D")
	
	var pos: Dictionary = data.get("position", {"x": 0, "y": 0})
	var zoom: Dictionary = data.get("zoom", {"x": 1, "y": 1})
	var rotation: float = data.get("rotation", 0.0)
	
	camera.position = Vector2(pos.x, pos.y)
	camera.zoom = Vector2(zoom.x, zoom.y)
	camera.rotation_degrees = rotation

## セーブファイルに書き込み
func _write_save_file(slot_id: int, data: Dictionary) -> bool:
	var path: String = _get_save_path(slot_id)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	
	if file == null:
		push_error("セーブファイルを開けません: " + path)
		return false
	
	# JSON形式で保存（圧縮版を将来実装可能）
	var json_string: String = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()
	
	return true

## セーブファイルから読み込み
func _read_save_file(slot_id: int) -> Dictionary:
	var path: String = _get_save_path(slot_id)
	
	if not FileAccess.file_exists(path):
		push_warning("セーブファイルが存在しません: " + path)
		return {}
	
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	
	if file == null:
		push_error("セーブファイルを開けません: " + path)
		return {}
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	
	if parse_result != OK:
		push_error("JSONの解析に失敗: " + json.get_error_message())
		return {}
	
	return json.data

## ゲーム状態を復元
func _restore_game_state(data: Dictionary) -> bool:
	# 復元順序が重要：
	# 1. 変数
	# 2. カメラ
	# 3. オーディオ
	# 4. キャラクター
	# 5. シナリオ（最後）
	
	# 変数を復元
	if data.has("variables"):
		VariableManager.load_save_data(data["variables"])
	
	# カメラを復元
	if data.has("camera"):
		_restore_camera_state(data["camera"])
	
	# オーディオを復元
	if data.has("audio"):
		AudioManager.load_state(data["audio"])
	
	# キャラクターを復元
	if data.has("characters") and game_manager.has_node("CharacterDisplay"):
		game_manager.character_display.load_state(data["characters"])
	
	# ウィンドウをクリア
	if game_manager.has_node("UI/MessageWindow"):
		game_manager.get_node("UI/MessageWindow").hide()
	
	# シナリオを復元（最後に実行）
	if data.has("scenario") and game_manager.has_node("ScenarioManager"):
		game_manager.scenario_manager.load_state(data["scenario"])
		
		# シナリオ再開（少し待機してから）
		await get_tree().create_timer(0.1).timeout
		if game_manager.scenario_manager.has_next():
			game_manager.scenario_manager.next_line()
	
	return true

## バージョン互換性チェック
func _is_compatible_version(saved_version: String) -> bool:
	# 簡易的なバージョンチェック（将来的により厳密に）
	var current_parts: PackedStringArray = SAVE_VERSION.split(".")
	var saved_parts: PackedStringArray = saved_version.split(".")
	
	if saved_parts.size() != 3:
		return false
	
	# メジャーバージョンが同じなら互換性あり
	return current_parts[0] == saved_parts[0]

## セーブスロット情報のキャッシュを構築
func _build_slot_cache() -> void:
	slot_cache.clear()
	
	var dir: DirAccess = DirAccess.open(SAVE_DIR)
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(SAVE_FILE_EXTENSION):
			var slot_id: int = _extract_slot_id(file_name)
			if slot_id != -999:  # 有効なスロット
				var metadata: Dictionary = _read_metadata(slot_id)
				if not metadata.is_empty():
					slot_cache[slot_id] = metadata
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

## ファイル名からスロットIDを抽出
func _extract_slot_id(filename: String) -> int:
	if filename.begins_with("autosave"):
		return SLOT_AUTO_SAVE
	elif filename.begins_with("quicksave"):
		return SLOT_QUICK_SAVE
	elif filename.begins_with("save_"):
		var num_str: String = filename.replace("save_", "").replace(SAVE_FILE_EXTENSION, "")
		if num_str.is_valid_int():
			return num_str.to_int()
	
	return -999  # 無効なスロット

## メタデータだけを読み込み
func _read_metadata(slot_id: int) -> Dictionary:
	var data: Dictionary = _read_save_file(slot_id)
	return data.get("metadata", {})

## キャッシュを更新
func _update_slot_cache(slot_id: int, metadata: Dictionary) -> void:
	slot_cache[slot_id] = metadata

## セーブスロット情報を取得
func get_slot_info(slot_id: int) -> Dictionary:
	if slot_cache.has(slot_id):
		return slot_cache[slot_id]
	
	# キャッシュになければファイルから読み込み
	var metadata: Dictionary = _read_metadata(slot_id)
	if not metadata.is_empty():
		slot_cache[slot_id] = metadata
	
	return metadata

## すべてのセーブスロット情報を取得
func get_all_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	
	for slot_id in slot_cache.keys():
		if slot_id > 0 and slot_id <= MAX_NORMAL_SLOTS:  # 通常セーブのみ
			slots.append(slot_cache[slot_id])
	
	# タイムスタンプでソート（新しい順）
	slots.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))
	
	return slots

## セーブスロットが存在するかチェック
func has_save(slot_id: int) -> bool:
	return FileAccess.file_exists(_get_save_path(slot_id))

## セーブスロットを削除
func delete_save(slot_id: int) -> bool:
	var path: String = _get_save_path(slot_id)
	
	if not FileAccess.file_exists(path):
		return false
	
	var err: Error = DirAccess.remove_absolute(path)
	
	if err == OK:
		slot_cache.erase(slot_id)
		print("セーブデータを削除: スロット %d" % slot_id)
		return true
	
	push_error("セーブデータの削除に失敗: " + str(err))
	return false
