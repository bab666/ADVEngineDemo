# D:\Works\Godot\ADVEngineDemo\scripts\ui\localized_label.gd
@tool
extends Label
class_name LocalizedLabel

## 自動的に翻訳されるLabel
## インスペクターで translation_key を設定するだけで使用可能
##
## 使用方法:
## 1. Labelの代わりにLocalizedLabelノードを作成
## 2. インスペクターで Translation Key に "Title.start_game" などを設定
## 3. 自動的に翻訳されたテキストが表示される

@export var translation_key: String = "":
	set(value):
		translation_key = value
		_update_text()

@export var translation_params: Array = []:
	set(value):
		translation_params = value
		_update_text()

func _ready() -> void:
	if not Engine.is_editor_hint():
		# ゲーム実行時のみ言語変更を監視
		if LocalizationManager:
			LocalizationManager.language_changed.connect(_on_language_changed)
	_update_text()

func _update_text() -> void:
	if translation_key.is_empty():
		return
	
	# エディタモードでは簡易表示
	if Engine.is_editor_hint():
		text = "[%s]" % translation_key
		return
	
	# ゲーム実行時は実際に翻訳
	if LocalizationManager:
		text = LocalizationManager.get_text(translation_key, translation_params)

func _on_language_changed(_new_language: String) -> void:
	_update_text()
