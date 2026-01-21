class_name SaveManager
extends Node

## セーブ・ロード管理システム
##
## 機能:
## - マルチスロット対応（通常セーブ + オートセーブ + クイックセーブ）
## - スナップショット方式（全システムの状態を保存）
## - メタデータ管理（日時、プレイ時間など）
## - 同期処理によるロード（コマンドからの呼び出しに対応）

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

## 初期化（GameManagerから呼ばれることを想定）
func setup(gm: Node) -> void:
	game_manager = gm

## セーブディレクトリを確保
func _ensure_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		var err: Error = DirAccess.make_dir_recursive_absolute(SAVE_DIR)
		if err != OK:
			push_error("セーブディレクトリの作成に失敗: " + str(err))

## スロットキャッシュを構築
func _build_slot_cache() -> void:
	slot_cache.clear()
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(SAVE_FILE_EXTENSION):
				var slot_id = _get_slot_id_from_filename(file_name)
				if slot_id != -999:
					var metadata = _read_metadata(slot_id)
					if not metadata.is_empty():
						slot_cache[slot_id] = metadata
			file_name = dir.get_next()

## ファイル名からスロットIDを取得
func _get_slot_id_from_filename(file_name: String) -> int:
	if file_name == "auto_save" + SAVE_FILE_EXTENSION:
		return SLOT_AUTO_SAVE
	elif file_name == "quick_save" + SAVE_FILE_EXTENSION:
		return SLOT_QUICK_SAVE
	elif file_name.begins_with("save_"):
		var num_str = file_name.replace("save_", "").replace(SAVE_FILE_EXTENSION, "")
		if num_str.is_valid_int():
			return num_str.to_int()
	return -999

## ファイルパスを取得
func _get_save_path(slot_id: int) -> String:
	var file_name = ""
	if slot_id == SLOT_AUTO_SAVE:
		file_name = "auto_save"
	elif slot_id == SLOT_QUICK_SAVE:
		file_name = "quick_save"
	else:
		file_name = "save_%03d" % slot_id
	return SAVE_DIR + file_name + SAVE_FILE_EXTENSION

## メタデータだけを読み込み
func _read_metadata(slot_id: int) -> Dictionary:
	var data: Dictionary = _read_save_file(slot_id)
	return data.get("metadata", {})

## セーブファイルを読み込み（内部用）
func _read_save_file(slot_id: int) -> Dictionary:
	var path = _get_save_path(slot_id)
	if not FileAccess.file_exists(path):
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	
	if error == OK:
		var data = json.data
		if data is Dictionary:
			return data
	
	return {}

## セーブを実行
func save_game(slot_id: int) -> bool:
	if not game_manager:
		push_error("GameManager is not set in SaveManager.")
		save_failed.emit(slot_id, "GameManager not set")
		return false
		
	var save_data = {
		"version": SAVE_VERSION,
		"metadata": _create_metadata(),
		"scenario": _capture_scenario_state(),
		"variables": game_manager.variables, # GameManagerの変数
		"characters": _capture_character_state(),
		"background": _capture_background_state(),
		"audio": _capture_audio_state()
	}
	
	var path = _get_save_path(slot_id)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		save_failed.emit(slot_id, "Failed to open file for write")
		return false
		
	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()
	
	# キャッシュ更新
	slot_cache[slot_id] = save_data["metadata"]
	
	save_completed.emit(slot_id)
	print("Game saved to slot: ", slot_id)
	return true

## メタデータ作成
func _create_metadata() -> Dictionary:
	return {
		"timestamp": Time.get_unix_time_from_system(),
		"datetime": Time.get_datetime_string_from_system(),
		"play_time": 0, # TODO: プレイ時間計測
		"current_text": "セーブデータのテキスト" # TODO: 現在のテキストを取得
	}

## ロードを実行（同期関数）
## 注意: この関数内に await を含めないでください。
func load_game(slot_id: int) -> bool:
	print("Loading game from slot: ", slot_id)
	
	var save_data: Dictionary = _read_save_file(slot_id)
	
	if save_data.is_empty():
		push_error("Save data not found or empty.")
		load_failed.emit(slot_id, "Data not found")
		return false

	# 同期的に状態を復元 (awaitなし)
	var success = _restore_game_state(save_data)
	
	if success:
		load_completed.emit(slot_id)
		print("Game loaded successfully.")
		return true
	else:
		load_failed.emit(slot_id, "Failed to restore state")
		return false

## ゲーム状態を復元（同期関数）
## 注意: この関数内にも await を含めないでください。
func _restore_game_state(data: Dictionary) -> bool:
	if not game_manager: 
		return false
	
	# 1. 変数の復元
	if data.has("variables"):
		game_manager.variables = data["variables"]
	
	# 2. シナリオ状態の復元
	if data.has("scenario"):
		# game_manager.scenario_manager.restore_state(data["scenario"])
		pass
	
	# 他の状態復元もここで行う
	# ...
	
	# 演出などで待機が必要な場合は、ロード完了後にGameManager側で行うこととし、
	# ここでは即座に完了させる。
	
	return true

# --- 各種状態取得ヘルパー (プレースホルダー) ---

func _capture_scenario_state() -> Dictionary:
	# game_manager.scenario_manager.get_state()
	return {}

func _capture_character_state() -> Dictionary:
	return {}

func _capture_background_state() -> Dictionary:
	return {}

func _capture_audio_state() -> Dictionary:
	return {}
