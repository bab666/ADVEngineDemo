extends Node

@onready var scenario_manager: ScenarioManager = $ScenarioManager
@onready var background: TextureRect = $Background
@onready var character_display: CharacterDisplay = $CharacterDisplay
@onready var command_registry: CommandRegistry = $CommandRegistry
@onready var camera: Camera2D = $Camera2D

var window_manager: WindowManager
var command_context: Dictionary = {}
var wait_tween: Tween
var is_scenario_paused: bool = false
var variables: Dictionary = {}

# --- タスク管理用 ---
var active_tasks: Array = []
# ★修正: 宣言漏れを追加 (タスクとIDの紐付け用)
var task_owners: Dictionary = {} 

func _ready():
	window_manager = get_node_or_null("WindowManager")
	if not window_manager:
		window_manager = WindowManager.new()
		window_manager.name = "WindowManager"
		add_child(window_manager)
	
	if has_node("UI/MessageWindow"): $UI/MessageWindow.hide()
	
	command_context = {
		"window_manager": window_manager,
		"background": background,
		"character_display": character_display,
		"scenario_manager": scenario_manager,
		"game_manager": self,
		"command_registry": command_registry,
		"camera": camera
	}
	
	if scenario_manager == null: return
	
	scenario_manager.scenario_line_changed.connect(_on_scenario_line_changed)
	scenario_manager.scenario_finished.connect(_on_scenario_finished)
	window_manager.advance_requested.connect(_on_advance_requested)
	
	print("=== ゲーム開始 ===")
	var loaded = scenario_manager.load_scenario("res://resources/scenarios/demo_scenario.txt")
	if loaded: scenario_manager.next_line()

func _on_scenario_line_changed(command: Dictionary):
	if is_scenario_paused: is_scenario_paused = false
	var command_type = command.get("type", "")
	print("コマンド実行: ", command)
	
	var requires_wait = command_registry.execute_command(command_type, command, command_context)
	
	if not requires_wait:
		if scenario_manager.has_next():
			await get_tree().create_timer(0.01).timeout
			scenario_manager.next_line()

func _on_advance_requested():
	if is_scenario_paused: return
	if scenario_manager.has_next(): scenario_manager.next_line()
	else: print("シナリオ終了")

func _on_scenario_finished():
	window_manager.hide_all_windows()

# --- 待機・ポーズ ---
func start_wait(time_sec: float) -> void:
	cancel_wait()
	wait_tween = create_tween()
	wait_tween.tween_interval(time_sec)
	wait_tween.finished.connect(_on_wait_finished)

func _on_wait_finished():
	if scenario_manager.has_next(): scenario_manager.next_line()

func cancel_wait() -> void:
	if wait_tween and wait_tween.is_valid(): wait_tween.kill()

func set_scenario_paused(paused: bool):
	is_scenario_paused = paused

func evaluate_expression(expression_str: String) -> bool:
	if expression_str.is_empty(): return true
	var expression = Expression.new()
	if expression.parse(expression_str, variables.keys()) != OK: return false
	var result = expression.execute(variables.values(), self)
	return bool(result) if not expression.has_execute_failed() else false

# --- ★タスク管理システム (修正版) ---

# Tweenなどをタスクとして登録
# ★修正: owner_id 引数を追加
func register_async_task(task: Variant, owner_id: String = ""):
	if task == null: return
	
	# Tweenの場合
	if task is Tween:
		if not task.is_valid(): return
		active_tasks.append(task)
		if not owner_id.is_empty():
			task_owners[task] = owner_id
		task.finished.connect(func(): _on_task_finished(task))
	
	# SequenceRunnerの場合
	elif task is SequenceRunner:
		active_tasks.append(task)
		if not owner_id.is_empty():
			task_owners[task] = owner_id
		task.finished_callback = func(): _on_task_finished(task)

func _on_task_finished(task):
	if active_tasks.has(task):
		active_tasks.erase(task)
	# ★修正: 完了時に辞書からも削除
	if task_owners.has(task):
		task_owners.erase(task)

# タスクの強制終了 (修正版)
func kill_active_tasks(target_id: String = ""):
	var tasks_to_remove = []
	
	for task in active_tasks:
		var is_target = false
		
		if target_id.is_empty():
			is_target = true
		elif task_owners.has(task) and task_owners[task] == target_id:
			is_target = true
		
		if is_target:
			if task is Tween:
				if task.is_valid(): task.kill()
			elif task is SequenceRunner:
				task.cancel()
			
			tasks_to_remove.append(task)
	
	for t in tasks_to_remove:
		active_tasks.erase(t)
		if task_owners.has(t):
			task_owners.erase(t)
	
	print("Killed %d tasks (Target: %s)" % [tasks_to_remove.size(), "ALL" if target_id.is_empty() else target_id])

# 全タスクの完了を待つ (Sync)
func wait_active_tasks(target_id: String = ""):
	while true:
		var has_running = false
		
		# 無効なタスクのお掃除も兼ねる
		var valid_tasks = []
		for t in active_tasks:
			var is_valid = false
			if t is Tween and t.is_valid() and t.is_running(): is_valid = true
			elif t is SequenceRunner and t.is_running: is_valid = true
			
			if is_valid:
				valid_tasks.append(t)
				# 待つ対象かチェック
				if target_id.is_empty():
					has_running = true
				elif task_owners.has(t) and task_owners[t] == target_id:
					has_running = true
		
		active_tasks = valid_tasks
		
		if not has_running: break
		
		await get_tree().process_frame

# --- 非同期シーケンス実行 ---
# ★修正: commandsリストを受け取って実行 (ID対応なし版)
# ID付きで実行したい場合は、RunSequenceCommand経由で register_async_task を呼ぶ形になるが、
# 簡易呼び出し用にここも対応しておくと便利
func run_sequence(commands: Array, id: String = ""):
	var runner = SequenceRunner.new(commands, command_context)
	# タスクとして登録してから開始
	register_async_task(runner, id)
	runner.start()
