# D:\Works\Godot\spelLDemo\scripts\game_manager_v2.gd
extends Node

@onready var scenario_manager: ScenarioManager = $ScenarioManager
@onready var message_window: MessageWindow = $UI/MessageWindow
@onready var background: TextureRect = $Background
@onready var character_display: CharacterDisplay = $CharacterDisplay
@onready var command_registry: CommandRegistry = $CommandRegistry

# コマンド実行時のコンテキスト
var command_context: Dictionary = {}

func _ready():
	# コマンドコンテキストを構築
	command_context = {
		"message_window": message_window,
		"background": background,
		"character_display": character_display,
		"scenario_manager": scenario_manager,
		"game_manager": self
	}
	
	if scenario_manager == null:
		push_error("ScenarioManager ノードが見つかりません")
		return
	
	scenario_manager.scenario_line_changed.connect(_on_scenario_line_changed)
	scenario_manager.scenario_finished.connect(_on_scenario_finished)
	message_window.advance_requested.connect(_on_advance_requested)
	
	print("=== ゲーム開始 ===")
	
	# デモシナリオ読み込み
	var loaded = scenario_manager.load_scenario("res://resources/scenarios/demo_scenario.txt")
	print("シナリオ読み込み結果: ", loaded)
	
	if loaded:
		scenario_manager.next_line()

func _on_scenario_line_changed(command: Dictionary):
	var command_type = command.get("type", "")
	print("コマンド実行: ", command)
	
	# CommandRegistry経由で実行
	var requires_wait = command_registry.execute_command(command_type, command, command_context)
	
	# 待機不要なコマンドは自動進行
	if not requires_wait:
		if scenario_manager.has_next():
			await get_tree().create_timer(0.1).timeout
			scenario_manager.next_line()

func _on_advance_requested():
	if scenario_manager.has_next():
		scenario_manager.next_line()
	else:
		print("シナリオ終了")

func _on_scenario_finished():
	print("全シナリオ終了")
	message_window.hide_window()
