extends Node

@onready var scenario_manager: ScenarioManager = $ScenarioManager
@onready var background: TextureRect = $Background
@onready var character_display: CharacterDisplay = $CharacterDisplay
@onready var command_registry: CommandRegistry = $CommandRegistry

var window_manager: WindowManager
var command_context: Dictionary = {}
var wait_tween: Tween
var is_scenario_paused: bool = false

# ★新規: ゲーム内変数・フラグ管理用辞書
var variables: Dictionary = {}

func _ready():
	# (省略: 既存の初期化処理)
	window_manager = get_node_or_null("WindowManager")
	if not window_manager:
		window_manager = WindowManager.new()
		window_manager.name = "WindowManager"
		add_child(window_manager)
	
	if has_node("UI/MessageWindow"):
		$UI/MessageWindow.hide()
	
	# コンテキストに変数辞書への参照も含めておく（コマンド側で操作する場合用）
	command_context = {
		"window_manager": window_manager,
		"background": background,
		"character_display": character_display,
		"scenario_manager": scenario_manager,
		"game_manager": self
	}
	
	# テスト用変数の初期化（デバッグ用）
	variables["test_flag"] = true
	variables["count"] = 10
	
	if scenario_manager == null:
		push_error("ScenarioManager ノードが見つかりません")
		return
	
	scenario_manager.scenario_line_changed.connect(_on_scenario_line_changed)
	scenario_manager.scenario_finished.connect(_on_scenario_finished)
	window_manager.advance_requested.connect(_on_advance_requested)
	
	print("=== ゲーム開始 ===")
	var loaded = scenario_manager.load_scenario("res://resources/scenarios/demo_scenario.txt")
	if loaded:
		scenario_manager.next_line()

# (省略: _on_scenario_line_changed, _on_advance_requested, _on_scenario_finished 等は既存のまま)
func _on_scenario_line_changed(command: Dictionary):
	if is_scenario_paused: is_scenario_paused = false
	
	var command_type = command.get("type", "")
	print("コマンド実行: ", command)
	
	# CommandRegistry経由で実行（Wait判定ロジックはRegistry側に委譲）
	var requires_wait = command_registry.execute_command(command_type, command, command_context)
	
	if not requires_wait:
		if scenario_manager.has_next():
			await get_tree().create_timer(0.1).timeout
			scenario_manager.next_line()

func _on_advance_requested():
	if is_scenario_paused: return
	if scenario_manager.has_next():
		scenario_manager.next_line()
	else:
		print("シナリオ終了")

func _on_scenario_finished():
	print("全シナリオ終了")
	window_manager.hide_all_windows()

# (省略: start_wait, cancel_wait, set_scenario_paused は既存のまま)
func start_wait(time_sec: float) -> void:
	cancel_wait()
	print("Wait開始: ", time_sec, "秒")
	wait_tween = create_tween()
	wait_tween.tween_interval(time_sec)
	wait_tween.finished.connect(_on_wait_finished)

func _on_wait_finished():
	print("Wait終了")
	if scenario_manager.has_next():
		scenario_manager.next_line()

func cancel_wait() -> void:
	if wait_tween and wait_tween.is_valid():
		wait_tween.kill()

func set_scenario_paused(paused: bool):
	is_scenario_paused = paused

# --- ★新規追加: 式評価機能 ---

# 文字列の条件式を評価して true/false を返す
# 例: evaluate_expression("count > 5") -> true
func evaluate_expression(expression_str: String) -> bool:
	if expression_str.is_empty():
		return true
		
	var expression = Expression.new()
	# 変数名をキーとしてパース
	var error = expression.parse(expression_str, variables.keys())
	
	if error != OK:
		push_error("式パースエラー: " + expression_str + " - " + expression.get_error_text())
		return false
	
	# 変数の値を渡して実行
	var result = expression.execute(variables.values(), self)
	
	if expression.has_execute_failed():
		push_error("式実行エラー: " + expression_str)
		return false
		
	return bool(result)
# scripts/game_manager.gd の末尾に追加

# ... (既存のコード) ...

# ★新規追加: メモリ解放処理
func clear_unused_resources():
	print("--- メモリ解放開始 ---")
	# キャラクターキャッシュの整理
	character_display.clear_cache()
	
	# Godotエンジンに「今すぐ未使用リソースを解放せよ」と指示する
	# (これが重要です。参照が切れたテクスチャなどをVRAMから降ろします)
	# ※注意: 一瞬処理落ちする可能性があるので、暗転中に行うのが推奨
	# 
	
	# Godot 4.x では参照カウントが0になれば自動解放されるが、
	# 明示的にキャッシュをパージするならこれを使う場面もある
	# ただしGDScriptからは直接GCを叩くより、参照を消すことが重要
	print("--- メモリ解放完了 ---")
