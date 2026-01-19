@tool
extends EditorPlugin

const EDITOR_SCENE = preload("res://addons/character_manager/character_editor.tscn")

var editor_instance: Control

func _enter_tree():
	# エディタのメインスクリーンに追加
	editor_instance = EDITOR_SCENE.instantiate()
	get_editor_interface().get_editor_main_screen().add_child(editor_instance)
	_make_visible(false)

func _exit_tree():
	if editor_instance:
		editor_instance.queue_free()

func _has_main_screen():
	return true

func _make_visible(visible):
	if editor_instance:
		editor_instance.visible = visible

func _get_plugin_name():
	return "Character Editor"

func _get_plugin_icon():
	# 必要に応じてアイコンを設定（標準のアイコンを使用）
	return get_editor_interface().get_base_control().get_theme_icon("CharacterBody2D", "EditorIcons")
