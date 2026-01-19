# D:\Works\Godot\spelLDemo\scripts\command_registry.gd
extends Node
class_name CommandRegistry

# 登録されたコマンド: コマンド名 -> BaseCommand インスタンス
var commands: Dictionary = {}

func _ready():
	# 組み込みコマンドを登録
	register_builtin_commands()

# 組み込みコマンドの登録
func register_builtin_commands():
	# 基本コマンド
	register_command(BgCommand.new())
	register_command(CharaCommand.new())
	register_command(CharaHideCommand.new())
	register_command(DialogueCommand.new())
	
	# オーディオコマンド
	register_command(BgmCommand.new())
	register_command(StopBgmCommand.new())
	register_command(StopSeCommand.new())
	
	print("=== 登録されたコマンド ===")
	for cmd_name in commands.keys():
		var cmd = commands[cmd_name]
		print("  @%s - %s" % [cmd_name, cmd.get_description()])
	print("========================")

# コマンドを登録
func register_command(command: BaseCommand) -> void:
	var cmd_name = command.get_command_name()
	if commands.has(cmd_name):
		push_warning("コマンド '%s' は既に登録されています。上書きします。" % cmd_name)
	
	commands[cmd_name] = command

# コマンドを取得
func get_command(cmd_name: String) -> BaseCommand:
	return commands.get(cmd_name, null)

# コマンドを実行
func execute_command(cmd_name: String, params: Dictionary, context: Dictionary) -> bool:
	var command = get_command(cmd_name)
	if command == null:
		push_warning("未知のコマンド: @%s" % cmd_name)
		return false
	
	command.execute(params, context)
	return command.requires_wait()

# コマンド一覧を取得（エディタ用）
func get_all_commands() -> Array:
	return commands.values()

# コマンドのドキュメント生成（開発用）
func generate_documentation() -> String:
	var doc = "# ADVコマンドリファレンス\n\n"
	
	var sorted_names = commands.keys()
	sorted_names.sort()
	
	for cmd_name in sorted_names:
		var cmd = commands[cmd_name]
		doc += "## @%s\n" % cmd_name
		doc += "%s\n\n" % cmd.get_description()
	
	return doc
