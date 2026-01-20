# D:\Works\Godot\ADVEngineDemo\scripts\localization_manager.gd
extends Node

## 多言語対応を管理するシングルトンクラス
## Autoloadとして登録されているため、class_name宣言は不要
##
## 使用方法:
## - LocalizationManager.get_text("Title.start_game") -> 翻訳されたテキストを取得
## - LocalizationManager.change_language("en") -> 言語を変更
## - LocalizationManager.language_changed.connect(callback) -> 言語変更を監視

signal language_changed(new_language: String)

const LOCALIZATION_PATH: String = "res://resources/localization/"
const DEFAULT_LANGUAGE: String = "ja"
const SUPPORTED_LANGUAGES: Array[String] = ["ja", "en"]

var current_language: String = DEFAULT_LANGUAGE
var translations: Dictionary = {}
var fallback_translations: Dictionary = {}

func _ready() -> void:
	_load_all_languages()
	_load_saved_language()

## すべての言語ファイルを読み込む
func _load_all_languages() -> void:
	for lang in SUPPORTED_LANGUAGES:
		_load_language_file(lang)
	
	# デフォルト言語をフォールバックとして設定
	if translations.has(DEFAULT_LANGUAGE):
		fallback_translations = translations[DEFAULT_LANGUAGE]

## 指定された言語ファイルを読み込む
func _load_language_file(language_code: String) -> bool:
	var file_path: String = LOCALIZATION_PATH + language_code + ".json"
	
	if not FileAccess.file_exists(file_path):
		push_error("言語ファイルが見つかりません: " + file_path)
		return false
	
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("言語ファイルを開けません: " + file_path)
		return false
	
	var json_text: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_text)
	
	if parse_result != OK:
		push_error("JSON解析エラー (%s): %s" % [file_path, json.get_error_message()])
		return false
	
	translations[language_code] = json.data
	return true

## 保存された言語設定を読み込む
func _load_saved_language() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load("user://settings.cfg")
	
	if err == OK:
		var saved_lang: String = config.get_value("general", "language", DEFAULT_LANGUAGE)
		if saved_lang in SUPPORTED_LANGUAGES:
			current_language = saved_lang
		else:
			current_language = DEFAULT_LANGUAGE
	else:
		current_language = DEFAULT_LANGUAGE

## 言語を変更する
func change_language(language_code: String) -> bool:
	if not language_code in SUPPORTED_LANGUAGES:
		push_warning("サポートされていない言語です: " + language_code)
		return false
	
	if language_code == current_language:
		return true
	
	current_language = language_code
	_save_language_setting()
	language_changed.emit(current_language)
	return true

## 言語設定を保存する
func _save_language_setting() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("general", "language", current_language)
	config.save("user://settings.cfg")

## 翻訳キーからテキストを取得する
## 
## 例: get_text("Title.start_game") -> "ゲームスタート" or "Start Game"
## パラメータ置換: get_text("Save.slot", [1]) -> "スロット 1" or "Slot 1"
func get_text(key: String, params: Array = []) -> String:
	var parts: PackedStringArray = key.split(".", false, 1)
	if parts.size() != 2:
		push_warning("無効な翻訳キー: " + key)
		return key
	
	var category: String = parts[0]
	var text_key: String = parts[1]
	
	# 現在の言語から翻訳を取得
	var text: String = _get_translation(category, text_key, current_language)
	
	# フォールバック: デフォルト言語から取得
	if text.is_empty() and current_language != DEFAULT_LANGUAGE:
		text = _get_translation(category, text_key, DEFAULT_LANGUAGE)
	
	# それでも見つからない場合はキーをそのまま返す
	if text.is_empty():
		push_warning("翻訳が見つかりません: " + key)
		return key
	
	# パラメータ置換
	if not params.is_empty():
		text = _format_string(text, params)
	
	return text

## 翻訳テキストを取得する内部関数
func _get_translation(category: String, text_key: String, language_code: String) -> String:
	if not translations.has(language_code):
		return ""
	
	var lang_data: Dictionary = translations[language_code]
	if not lang_data.has(category):
		return ""
	
	var category_data: Dictionary = lang_data[category]
	if not category_data.has(text_key):
		return ""
	
	return category_data[text_key]

## 文字列フォーマット（{0}, {1}, ... を置換）
func _format_string(text: String, params: Array) -> String:
	var result: String = text
	for i in range(params.size()):
		result = result.replace("{%d}" % i, str(params[i]))
	return result

## 現在の言語コードを取得
func get_current_language() -> String:
	return current_language

## 現在の言語の表示名を取得
func get_current_language_name() -> String:
	if not translations.has(current_language):
		return current_language
	
	var lang_data: Dictionary = translations[current_language]
	if lang_data.has("_metadata") and lang_data["_metadata"].has("language"):
		return lang_data["_metadata"]["language"]
	
	return current_language

## サポートされている言語のリストを取得
func get_supported_languages() -> Array[String]:
	return SUPPORTED_LANGUAGES.duplicate()

## 言語の表示名リストを取得
func get_language_names() -> Dictionary:
	var names: Dictionary = {}
	for lang in SUPPORTED_LANGUAGES:
		if translations.has(lang):
			var lang_data: Dictionary = translations[lang]
			if lang_data.has("_metadata") and lang_data["_metadata"].has("language"):
				names[lang] = lang_data["_metadata"]["language"]
			else:
				names[lang] = lang
	return names

## カテゴリ内のすべてのキーを取得（デバッグ用）
func get_category_keys(category: String) -> Array:
	if not translations.has(current_language):
		return []
	
	var lang_data: Dictionary = translations[current_language]
	if not lang_data.has(category):
		return []
	
	return lang_data[category].keys()

## すべてのカテゴリを取得（デバッグ用）
func get_all_categories() -> Array:
	if not translations.has(current_language):
		return []
	
	var categories: Array = []
	for key in translations[current_language].keys():
		if key != "_metadata":
			categories.append(key)
	return categories

## カテゴリを省略してキーから翻訳を検索（シナリオ用）
## 
## 例: get_text_by_key("start_game") -> 全カテゴリから"start_game"を検索
func get_text_by_key(key: String, params: Array = []) -> String:
	if not translations.has(current_language):
		return key
	
	var lang_data: Dictionary = translations[current_language]
	
	# 全カテゴリを検索
	for category in lang_data.keys():
		if category == "_metadata":
			continue
		
		var category_data: Dictionary = lang_data[category]
		if category_data.has(key):
			var text: String = category_data[key]
			
			# パラメータ置換
			if not params.is_empty():
				text = _format_string(text, params)
			
			return text
	
	# 見つからない場合はキーをそのまま返す
	push_warning("カテゴリ省略検索で翻訳が見つかりません: " + key)
	return key

## シナリオテキスト内の翻訳ラベルを置換（BBCode対応）
## 
## 例: parse_scenario_text("こんにちは、{T_player_name}!") -> "こんにちは、プレイヤー!"
func parse_scenario_text(text: String) -> String:
	var result: String = text
	var regex: RegEx = RegEx.new()
	
	# {T_key} 形式のパターンを検索
	regex.compile("\\{T_([^}]+)\\}")
	
	var matches: Array[RegExMatch] = regex.search_all(result)
	for match in matches:
		var full_match: String = match.get_string(0)  # {T_key} 全体
		var key: String = match.get_string(1)  # key 部分
		
		# 翻訳を取得
		var translated_text: String = get_text_by_key(key)
		
		# 置換
		result = result.replace(full_match, translated_text)
	
	return result
