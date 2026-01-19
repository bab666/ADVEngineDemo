@tool
extends EditorPlugin

## アドオンが有効化されたときに呼ばれます
func _enter_tree() -> void:
	# ここに初期化処理を書きます（ドックの追加など）
	print("My First Addon: 有効化されました！")

## アドオンが無効化されたときに呼ばれます
func _exit_tree() -> void:
	# ここに終了処理を書きます（ドックの削除、メモリ解放など）
	# 重要: ここで片付けを忘れるとメモリリークの原因になります
	print("My First Addon: 無効化されました。")
