# D:\Works\Godot\spelLDemo\scripts\message_window.gd
extends Control
class_name MessageWindow

@onready var name_label: Label = $Panel/MarginContainer/VBoxContainer/NameLabel
@onready var text_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/TextLabel
@onready var panel: Panel = $Panel

var is_text_complete: bool = true
var current_text: String = ""
var display_speed: float = 0.05
var char_index: int = 0

signal text_completed
signal advance_requested

func _ready():
	# テスト用に最初から表示
	show()
	print("MessageWindow _ready 完了")
	print("visible: ", visible)
	print("name_label: ", name_label)
	print("text_label: ", text_label)

func show_dialogue(character_name: String, text: String):
	print("=== show_dialogue 呼び出し ===")
	print("表示前 visible: ", visible)
	show()
	print("表示後 visible: ", visible)
	print("Panel: ", panel)
	
	name_label.text = character_name
	current_text = text
	char_index = 0
	is_text_complete = false
	text_label.text = ""
	
	print("name_label.text: ", name_label.text)
	print("name_label.visible: ", name_label.visible)
	
	_display_text()

func _display_text():
	if char_index < current_text.length():
		text_label.text = current_text.substr(0, char_index + 1)
		char_index += 1
		await get_tree().create_timer(display_speed).timeout
		_display_text()
	else:
		is_text_complete = true
		text_completed.emit()

func skip_text():
	if not is_text_complete:
		text_label.text = current_text
		char_index = current_text.length()
		is_text_complete = true
		text_completed.emit()

func _input(event):
	if not visible:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_advance_input()
	elif event.is_action_pressed("ui_accept"):
		_on_advance_input()

func _on_advance_input():
	if is_text_complete:
		advance_requested.emit()
	else:
		skip_text()

func hide_window():
	hide()
