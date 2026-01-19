extends Control
class_name MessageWindow

# --- UI参照 (継承先のシーンに合わせてパスをオーバーライド可能にする) ---
@export var name_label_path: NodePath = "Panel/MarginContainer/VBoxContainer/NameLabel"
@export var text_label_path: NodePath = "Panel/MarginContainer/VBoxContainer/TextLabel"
@export var panel_path: NodePath = "Panel"

@onready var name_label: Label = get_node_or_null(name_label_path)
@onready var text_label: RichTextLabel = get_node_or_null(text_label_path)
@onready var panel: Panel = get_node_or_null(panel_path)

# --- 設定パラメータ (JSONから注入) ---
var config: Dictionary = {}
var text_speed: float = 0.05
var auto_advance: bool = false
var input_wait: bool = true

# --- 状態管理 ---
var is_typing: bool = false
var current_text: String = ""
var visible_characters: int = 0

signal text_completed
signal advance_requested

func _ready():
	# 初期化時は非表示など
	if text_label:
		text_label.bbcode_enabled = true # BBコード(文字演出)を有効化
		text_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING

# 設定を適用するメソッド
func setup(window_config: Dictionary):
	config = window_config
	text_speed = config.get("text_speed", 0.05)
	auto_advance = config.get("auto_advance", false)
	input_wait = config.get("input_wait", true)
	
	# 位置とサイズの適用
	if config.has("pos"):
		var p = config["pos"]
		position = Vector2(p.x, p.y)
	
	if panel and config.has("size"):
		var s = config["size"]
		panel.custom_minimum_size = Vector2(s.x, s.y)
		panel.size = Vector2(s.x, s.y) # 即時反映
	
	# フォント設定の適用 (RichTextLabelのtheme override)
	if text_label and config.has("font_size"):
		text_label.add_theme_font_size_override("normal_font_size", config["font_size"])
		text_label.add_theme_font_size_override("bold_font_size", config["font_size"])
	
	if name_label and config.has("name_font_size"):
		name_label.add_theme_font_size_override("font_size", config["name_font_size"])

# テキスト表示実行
func show_dialogue(character_name: String, text: String):
	show()
	
	if name_label:
		name_label.text = character_name
		name_label.visible = not character_name.is_empty()
	
	if text_label:
		current_text = text
		text_label.text = current_text # BBCode解析のため一度全セット
		text_label.visible_characters = 0 # 表示文字数を0に
		visible_characters = 0
		is_typing = true
		
		# 文字送り開始
		_start_typing()

# タイピング演出 (Tweenを使用)
func _start_typing():
	if text_speed <= 0:
		# 瞬間表示
		text_label.visible_characters = -1
		_on_typing_finished()
		return

	# 文字数取得 (BBCodeタグを除いた純粋な文字数)
	var total_chars = text_label.get_parsed_text().length()
	var duration = total_chars * text_speed
	
	var tween = create_tween()
	tween.tween_property(text_label, "visible_characters", total_chars, duration)
	tween.finished.connect(_on_typing_finished)

func _on_typing_finished():
	is_typing = false
	text_completed.emit()
	
	# 自動送りの場合
	if auto_advance:
		await get_tree().create_timer(1.0).timeout # 待機時間は設定化しても良い
		advance_requested.emit()

# テキストのスキップ（瞬間表示）
func skip_typing():
	if is_typing and text_label:
		# Tweenを強制終了させる等の処理が必要だが、簡易的にプロパティ上書き
		# (Tweenのkill管理をするのがベストだが、ここではシンプルに)
		text_label.visible_characters = -1 # 全表示
		is_typing = false
		text_completed.emit()

# 入力ハンドリング
func _input(event):
	if not visible or not input_wait:
		return
	
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_advance_input()

func _on_advance_input():
	if is_typing:
		skip_typing()
	else:
		advance_requested.emit()

func hide_window():
	hide()
