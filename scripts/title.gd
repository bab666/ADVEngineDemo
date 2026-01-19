# D:\Works\Godot\spelLDemo\scripts\title.gd
extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var load_button: Button = $VBoxContainer/LoadButton
@onready var config_button: Button = $VBoxContainer/ConfigButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	config_button.pressed.connect(_on_config_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# ロード機能未実装の場合は無効化
	load_button.disabled = true
	
	# タイトルBGM再生
	AudioManager.play_bgm("title", 2.0)

func _on_start_pressed():
	print("ゲーム開始")
	# BGMフェードアウトしてからシーン遷移
	await AudioManager.fade_out_bgm(1.0)
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_load_pressed():
	print("ロード（未実装）")
	# TODO: セーブデータ選択画面へ遷移

func _on_config_pressed():
	print("設定（未実装）")
	# TODO: 設定画面へ遷移

func _on_quit_pressed():
	print("終了")
	get_tree().quit()
