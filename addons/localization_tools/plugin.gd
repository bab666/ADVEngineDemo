# D:\Works\Godot\ADVEngineDemo\addons\localization_tools\plugin.gd
@tool
extends EditorPlugin

const LocalizationPanel = preload("res://addons/localization_tools/localization_panel.gd")

var panel_instance: Control

func _enter_tree() -> void:
	# ドックパネルを追加
	panel_instance = LocalizationPanel.new()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, panel_instance)

func _exit_tree() -> void:
	# プラグイン無効化時にパネルを削除
	if panel_instance:
		remove_control_from_docks(panel_instance)
		panel_instance.queue_free()
