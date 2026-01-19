extends Node
class_name CommandRegistry

var commands: Dictionary = {}

func _ready():
	register_builtin_commands()

func register_builtin_commands():
	# 基本コマンド
	register_command(BgCommand.new())
	register_command(CharaCommand.new())
	register_command(CharaHideCommand.new())
	register_command(DialogueCommand.new())
	register_command(WindowCommand.new())

	# ★新規追加: Wait関連コマンド
	register_command(WaitCommand.new())
	register_command(WaitCancelCommand.new())
	
	# ★新規追加: ジャンプ系コマンド
	register_command(JumpCommand.new())
	register_command(CallCommand.new())
	register_command(ReturnCommand.new())
	register_command(StopCommand.new())	
	# オーディオコマンド
	register_command(BgmCommand.new())
	register_command(StopBgmCommand.new())
	register_command(StopSeCommand.new())
	# メモリリリースコマンド
	register_command(ClearMemoryCommand.new())
	# 非同期・同期処理コマンド
	register_command(RunSequenceCommand.new())
	register_command(SyncCommand.new())
	# 演出コマンド
	register_command(CameraCommand.new())

	print("=== 登録されたコマンド一覧 ===")
	for key in commands.keys():
		print("@" + key)

func register_command(command: BaseCommand) -> void:
	var cmd_name = command.get_command_name()
	if commands.has(cmd_name):
		push_warning("コマンド '%s' は既に登録されています。上書きします。" % cmd_name)
	commands[cmd_name] = command

func get_command(cmd_name: String) -> BaseCommand:
	return commands.get(cmd_name, null)

func execute_command(cmd_name: String, params: Dictionary, context: Dictionary) -> bool:
	var command = get_command(cmd_name)
	if command == null:
		push_warning("未知のコマンド: @%s" % cmd_name)
		return false
	
	command.execute(params, context)
	return command.requires_wait()
