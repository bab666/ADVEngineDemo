extends Node
class_name WindowManager

# 管理しているウインドウのインスタンス: window_id -> MessageWindow
var active_windows: Dictionary = {}

# 設定データ
var window_configs: Dictionary = {}
const CONFIG_PATH = "res://resources/system/window_config.json"

# 現在アクティブな（コマンド対象の）ウインドウID
var current_window_id: String = "default"

signal advance_requested # 現在のウインドウからの進行要求を中継

func _ready():
	_load_configs()

# 設定ファイルの読み込み
func _load_configs():
	if FileAccess.file_exists(CONFIG_PATH):
		var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			window_configs = json.data
		else:
			push_error("Window Config JSON Parse Error")
	else:
		push_warning("Window Config not found: " + CONFIG_PATH)

# ウインドウの取得（存在しなければ生成）
func get_message_window(window_id: String) -> MessageWindow:
	if active_windows.has(window_id):
		return active_windows[window_id]
	
	return _create_window(window_id)

# ウインドウの生成
func _create_window(window_id: String) -> MessageWindow:
	# 設定の取得（IDがなければ default をフォールバック）
	var config = window_configs.get(window_id, window_configs.get("default", {}))
	
	# シーンのロード
	# 設定にパスがなければ、現在のgame.tscnにある既存のパスなどをデフォルトにする等の安全策
	var scene_path = config.get("scene_path", "res://scenes/ui/windows/default_window.tscn")
	
	if not ResourceLoader.exists(scene_path):
		push_error("Window scene not found: " + scene_path)
		return null
		
	var scene = load(scene_path).instantiate()
	
	# シーンツリーに追加 (GameManager -> UIレイヤーの下などを想定)
	# ※ ここではWindowManagerの子として追加するが、実際はCanvasLayer下に置きたい
	# 親を見つけて追加する処理
	var ui_root = get_tree().root.find_child("UI", true, false)
	if ui_root:
		ui_root.add_child(scene)
	else:
		add_child(scene) # フォールバック
	
	var window = scene as MessageWindow
	if window:
		window.setup(config)
		window.hide() # 最初は隠す
		
		# シグナルの中継
		window.advance_requested.connect(func(): advance_requested.emit())
		
		active_windows[window_id] = window
		return window
	else:
		push_error("Scene is not a MessageWindow: " + scene_path)
		scene.queue_free()
		return null

func set_current_window(window_id: String):
	if window_configs.has(window_id):
		# 前のウインドウを隠すかどうかは仕様によりますが、
		# ここでは切り替え時に前のウインドウを隠す設定にします
		# (必要なければ hide_window() の行を削除してください)
		if active_windows.has(current_window_id):
			active_windows[current_window_id].hide_window()
			
		current_window_id = window_id
		print("Active Window Changed: ", current_window_id)
	else:
		push_warning("Window Config not found: " + window_id)

# ダイアログ表示のラッパー (2026/01/19修正)
func show_dialogue(_unused_id: String, character_name: String, text: String):
	# 第一引数は無視して、設定された current_window_id を使うように変更
	var win = get_message_window(current_window_id)
	if win:
		win.show_dialogue(character_name, text)

func hide_all_windows():
	for win in active_windows.values():
		win.hide_window()
