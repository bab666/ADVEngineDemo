extends RefCounted
class_name SequenceRunner

var command_list: Array[Dictionary] = []
var current_index: int = 0
var context: Dictionary = {}
var finished_callback: Callable
var is_running: bool = false

func _init(commands: Array, ctx: Dictionary):
	command_list = commands
	# ★修正: コンテキストを複製し、非同期フラグを立てる
	context = ctx.duplicate()
	context["is_async"] = true

func start():
	is_running = true
	current_index = 0
	_execute_next()

func cancel():
	is_running = false

func _execute_next():
	if not is_running: return
	
	if current_index >= command_list.size():
		_finish()
		return
	
	var command_data = command_list[current_index]
	var cmd_type = command_data.get("type", "")
	
	var registry = context.get("command_registry")
	if registry:
		# ★追加: コマンド実行前に前回のTween情報をリセット
		context["current_tween"] = null
		
		# コマンド実行
		var requires_wait = registry.execute_command(cmd_type, command_data, context)
		current_index += 1
		
		if requires_wait:
			# ★修正: GameManagerのwaitではなく、コマンドが生成したTweenを直接待つ
			var tween = context.get("current_tween")
			if tween and tween.is_valid():
				await tween.finished
				_execute_next()
			else:
				# Tweenがない場合は安全のため少し待つ（無限ループ防止）
				var gm = context.get("game_manager")
				if gm: await gm.get_tree().create_timer(0.01).timeout
				_execute_next()
		else:
			var gm = context.get("game_manager")
			if gm: await gm.get_tree().process_frame # 負荷分散
			_execute_next()

func _finish():
	is_running = false
	if finished_callback: finished_callback.call()
