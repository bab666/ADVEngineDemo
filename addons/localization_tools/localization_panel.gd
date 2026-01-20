# D:\Works\Godot\ADVEngineDemo\addons\localization_tools\localization_panel.gd
@tool
extends VBoxContainer

const LOCALIZATION_PATH: String = "res://resources/localization/"
const BASE_LANGUAGE: String = "ja"
const TARGET_LANGUAGES: Array[String] = ["en", "zh", "ko", "es", "fr", "de"]

var status_label: Label
var generate_button: Button
var language_options: VBoxContainer

func _init() -> void:
	name = "Localization Tools"
	
	# タイトルラベル
	var title: Label = Label.new()
	title.text = "翻訳ファイル自動生成"
	title.add_theme_font_size_override("font_size", 16)
	add_child(title)
	
	add_child(HSeparator.new())
	
	# 説明
	var description: Label = Label.new()
	description.text = "日本語ファイル(ja.json)を基に、他の言語ファイルを自動生成します。"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(description)
	
	add_child(HSeparator.new())
	
	# 言語選択
	var lang_label: Label = Label.new()
	lang_label.text = "生成する言語:"
	add_child(lang_label)
	
	language_options = VBoxContainer.new()
	for lang in TARGET_LANGUAGES:
		var check_box: CheckBox = CheckBox.new()
		check_box.text = _get_language_name(lang)
		check_box.name = lang
		check_box.button_pressed = true  # デフォルトで全選択
		language_options.add_child(check_box)
	add_child(language_options)
	
	add_child(HSeparator.new())
	
	# 生成ボタン
	generate_button = Button.new()
	generate_button.text = "翻訳ファイルを生成"
	generate_button.pressed.connect(_on_generate_pressed)
	add_child(generate_button)
	
	# ステータス表示
	status_label = Label.new()
	status_label.text = "準備完了"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status_label)

func _get_language_name(code: String) -> String:
	var names: Dictionary = {
		"en": "英語 (English)",
		"zh": "中国語 (简体中文)",
		"ko": "韓国語 (한국어)",
		"es": "スペイン語 (Español)",
		"fr": "フランス語 (Français)",
		"de": "ドイツ語 (Deutsch)"
	}
	return names.get(code, code)

func _on_generate_pressed() -> void:
	status_label.text = "生成中..."
	
	# 日本語ファイルを読み込み
	var base_file_path: String = LOCALIZATION_PATH + BASE_LANGUAGE + ".json"
	if not FileAccess.file_exists(base_file_path):
		status_label.text = "エラー: ja.json が見つかりません"
		return
	
	var file: FileAccess = FileAccess.open(base_file_path, FileAccess.READ)
	if file == null:
		status_label.text = "エラー: ja.json を開けません"
		return
	
	var json_text: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_text)
	
	if parse_result != OK:
		status_label.text = "エラー: JSON解析に失敗しました"
		return
	
	var base_data: Dictionary = json.data
	var generated_count: int = 0
	
	# 選択された言語ファイルを生成
	for child in language_options.get_children():
		if child is CheckBox and child.button_pressed:
			var lang_code: String = child.name
			if _generate_language_file(lang_code, base_data):
				generated_count += 1
	
	status_label.text = "完了: %d個の言語ファイルを生成しました" % generated_count
	
	# ファイルシステムを更新
	EditorInterface.get_resource_filesystem().scan()

func _generate_language_file(language_code: String, base_data: Dictionary) -> bool:
	var target_file_path: String = LOCALIZATION_PATH + language_code + ".json"
	
	# 既存ファイルがある場合は読み込んで既存の翻訳を保持
	var existing_data: Dictionary = {}
	if FileAccess.file_exists(target_file_path):
		var existing_file: FileAccess = FileAccess.open(target_file_path, FileAccess.READ)
		if existing_file:
			var existing_json: JSON = JSON.new()
			if existing_json.parse(existing_file.get_as_text()) == OK:
				existing_data = existing_json.data
			existing_file.close()
	
	# 新しいデータを構築（既存の翻訳は保持、新しいキーは日本語をプレースホルダーとして追加）
	var new_data: Dictionary = _merge_translations(base_data, existing_data, language_code)
	
	# JSONファイルとして保存
	var output_file: FileAccess = FileAccess.open(target_file_path, FileAccess.WRITE)
	if output_file == null:
		push_error("ファイルを作成できません: " + target_file_path)
		return false
	
	output_file.store_string(JSON.stringify(new_data, "\t"))
	output_file.close()
	
	print("生成完了: " + target_file_path)
	return true

func _merge_translations(base_data: Dictionary, existing_data: Dictionary, language_code: String) -> Dictionary:
	var result: Dictionary = {}
	
	# メタデータを設定
	result["_metadata"] = {
		"language": _get_language_name(language_code),
		"language_code": language_code,
		"version": "1.0.0",
		"last_updated": Time.get_datetime_string_from_system()
	}
	
	# 各カテゴリを処理
	for category in base_data.keys():
		if category == "_metadata":
			continue
		
		result[category] = {}
		var base_category: Dictionary = base_data[category]
		var existing_category: Dictionary = existing_data.get(category, {})
		
		# 各キーを処理
		for key in base_category.keys():
			# 既存の翻訳があればそれを使用、なければ日本語をプレースホルダーとして使用
			if existing_category.has(key):
				result[category][key] = existing_category[key]
			else:
				# 新しいキーは [TO TRANSLATE] プレフィックスを付ける
				result[category][key] = "[TO TRANSLATE] " + base_category[key]
	
	return result
