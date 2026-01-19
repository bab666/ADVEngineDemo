extends RefCounted
class_name BaseCommand

# コマンド名（例: "bg", "chara", "bgm"）
func get_command_name() -> String:
	push_error("get_command_name() must be implemented")
	return ""

# コマンドの説明（ドキュメント用）
func get_description() -> String:
	return "No description"

# コマンドを実行
# --- 修正: 使っていない引数に _ をつける ---
func execute(_params: Dictionary, _context: Dictionary) -> void:
	push_error("execute() must be implemented")
# ----------------------------------------

# コマンドが即座実行か待機が必要か
func requires_wait() -> bool:
	return false

# コマンドの優先度
func get_priority() -> int:
	return 0
