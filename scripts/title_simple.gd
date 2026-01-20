# D:\Works\Godot\ADVEngineDemo\scripts\title_simple.gd
extends Control

## タイトル画面（簡易版）
## LocalizedButton を使用しているため、スクリプトでの翻訳処理は不要

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var load_button: Button = $VBoxContainer/LoadButton
@onready var config_button: Button = $VBoxContainer/ConfigButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	# ボタンイベントのみ接続（翻訳は LocalizedButton が自動処理）
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	config_button.pressed.connect(_on_config_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# ロード機能未実装の場合は無効化
	load_button.disabled = true
	
	# タイトルBGM再生
	AudioManager.play_bgm("title", 2.0)

func _on_start_pressed() -> void:
	print("ゲーム開始")
	# BGMフェードアウトしてからシーン遷移
	await AudioManager.fade_out_bgm(1.0)
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_load_pressed() -> void:
	print("ロード（未実装）")
	# TODO: セーブデータ選択画面へ遷移

func _on_config_pressed() -> void:
	print("設定（未実装）")
	# TODO: 設定画面へ遷移

func _on_quit_pressed() -> void:
	print("終了")
	get_tree().quit()
