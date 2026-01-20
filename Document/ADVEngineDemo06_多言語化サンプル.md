# ADVEngineDemo 多言語化実装サンプル集

## サンプル1: 設定画面での言語切り替え

### 画面構成

```
SettingsScreen (Control)
├── TitleLabel (Label)
├── VBoxContainer
│   ├── LanguageContainer (HBoxContainer)
│   │   ├── LanguageLabel (Label)
│   │   └── LanguageOption (OptionButton)
│   ├── VolumeContainer (HBoxContainer)
│   │   ├── VolumeLabel (Label)
│   │   └── VolumeSlider (HSlider)
│   └── BackButton (Button)
```

### スクリプト例

```gdscript
# settings_screen.gd
extends Control

@onready var title_label: Label = $TitleLabel
@onready var language_label: Label = $VBoxContainer/LanguageContainer/LanguageLabel
@onready var language_option: OptionButton = $VBoxContainer/LanguageContainer/LanguageOption
@onready var volume_label: Label = $VBoxContainer/VolumeContainer/VolumeLabel
@onready var volume_slider: HSlider = $VBoxContainer/VolumeContainer/VolumeSlider
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
    # 言語選択肢を設定
    _setup_language_options()
    
    # 言語変更を監視
    LocalizationManager.language_changed.connect(_update_ui_text)
    
    # UI初期化
    _update_ui_text(LocalizationManager.get_current_language())
    
    # イベント接続
    language_option.item_selected.connect(_on_language_selected)
    back_button.pressed.connect(_on_back_pressed)

func _setup_language_options() -> void:
    language_option.clear()
    
    var lang_names: Dictionary = LocalizationManager.get_language_names()
    var current_lang: String = LocalizationManager.get_current_language()
    var index: int = 0
    
    for lang_code in lang_names.keys():
        language_option.add_item(lang_names[lang_code])
        language_option.set_item_metadata(index, lang_code)
        
        if lang_code == current_lang:
            language_option.selected = index
        
        index += 1

func _update_ui_text(_language: String) -> void:
    title_label.text = LocalizationManager.tr("Settings.title")
    language_label.text = LocalizationManager.tr("Settings.language")
    volume_label.text = LocalizationManager.tr("Settings.bgm_volume")
    back_button.text = LocalizationManager.tr("Settings.back")

func _on_language_selected(index: int) -> void:
    var lang_code: String = language_option.get_item_metadata(index)
    LocalizationManager.change_language(lang_code)

func _on_back_pressed() -> void:
    # 前の画面に戻る
    get_tree().change_scene_to_file("res://scenes/title.tscn")
```

---

## サンプル2: セーブ/ロード画面

### スクリプト例

```gdscript
# save_load_screen.gd
extends Control

const SAVE_SLOTS: int = 10

@onready var title_label: Label = $TitleLabel
@onready var slots_container: VBoxContainer = $ScrollContainer/SlotsContainer

class SaveSlotButton extends Button:
    var slot_index: int
    var has_data: bool
    var save_date: String

func _ready() -> void:
    LocalizationManager.language_changed.connect(_update_ui_text)
    _create_save_slots()
    _update_ui_text(LocalizationManager.get_current_language())

func _create_save_slots() -> void:
    for i in range(SAVE_SLOTS):
        var slot_button: SaveSlotButton = SaveSlotButton.new()
        slot_button.slot_index = i
        slot_button.custom_minimum_size = Vector2(400, 60)
        slot_button.pressed.connect(_on_slot_pressed.bind(i))
        slots_container.add_child(slot_button)
        
        # セーブデータの存在確認（仮）
        slot_button.has_data = _check_save_data(i)
        
        _update_slot_text(slot_button)

func _update_ui_text(_language: String) -> void:
    title_label.text = LocalizationManager.tr("Save.title")
    
    # すべてのスロットのテキストを更新
    for child in slots_container.get_children():
        if child is SaveSlotButton:
            _update_slot_text(child)

func _update_slot_text(slot: SaveSlotButton) -> void:
    if slot.has_data:
        # データがある場合: "スロット 1 - 2025年1月20日 14:30"
        slot.text = "%s - %s" % [
            LocalizationManager.tr("Save.slot", [slot.slot_index + 1]),
            slot.save_date
        ]
    else:
        # データがない場合: "スロット 1 - データなし"
        slot.text = "%s - %s" % [
            LocalizationManager.tr("Save.slot", [slot.slot_index + 1]),
            LocalizationManager.tr("Save.empty")
        ]

func _check_save_data(slot_index: int) -> bool:
    # 実際の実装ではセーブデータの存在確認を行う
    return slot_index < 3  # デモ用: 最初の3スロットにデータありとする

func _on_slot_pressed(slot_index: int) -> void:
    # セーブ/ロード処理
    var message: String = LocalizationManager.tr("Save.slot", [slot_index + 1])
    print("選択されたスロット: ", message)
```

---

## サンプル3: ダイアログ表示

### スクリプト例

```gdscript
# confirmation_dialog.gd
extends ConfirmationDialog

signal confirmed
signal cancelled

func _ready() -> void:
    LocalizationManager.language_changed.connect(_update_ui_text)
    confirmed.connect(_on_confirmed)
    cancelled.connect(_on_cancelled)
    _update_ui_text(LocalizationManager.get_current_language())

func _update_ui_text(_language: String) -> void:
    ok_button_text = LocalizationManager.tr("Save.yes")
    cancel_button_text = LocalizationManager.tr("Save.no")

func show_overwrite_confirmation(slot_number: int) -> void:
    title = LocalizationManager.tr("System.confirm")
    dialog_text = LocalizationManager.tr("Save.confirm_overwrite")
    popup_centered()

func _on_confirmed() -> void:
    print("確認されました")

func _on_cancelled() -> void:
    print("キャンセルされました")
```

---

## サンプル4: ゲームUI（クイックメニュー）

### スクリプト例

```gdscript
# game_quick_menu.gd
extends Control

@onready var save_button: Button = $HBoxContainer/SaveButton
@onready var load_button: Button = $HBoxContainer/LoadButton
@onready var auto_button: Button = $HBoxContainer/AutoButton
@onready var skip_button: Button = $HBoxContainer/SkipButton
@onready var log_button: Button = $HBoxContainer/LogButton
@onready var config_button: Button = $HBoxContainer/ConfigButton

func _ready() -> void:
    LocalizationManager.language_changed.connect(_update_ui_text)
    _update_ui_text(LocalizationManager.get_current_language())
    
    # イベント接続
    save_button.pressed.connect(_on_save_pressed)
    load_button.pressed.connect(_on_load_pressed)
    auto_button.pressed.connect(_on_auto_pressed)
    skip_button.pressed.connect(_on_skip_pressed)
    log_button.pressed.connect(_on_log_pressed)
    config_button.pressed.connect(_on_config_pressed)

func _update_ui_text(_language: String) -> void:
    save_button.text = LocalizationManager.tr("GameUI.save")
    load_button.text = LocalizationManager.tr("GameUI.load")
    auto_button.text = LocalizationManager.tr("GameUI.auto")
    skip_button.text = LocalizationManager.tr("GameUI.skip")
    log_button.text = LocalizationManager.tr("GameUI.log")
    config_button.text = LocalizationManager.tr("GameUI.config")

func _on_save_pressed() -> void:
    print("セーブ画面を開く")

func _on_load_pressed() -> void:
    print("ロード画面を開く")

func _on_auto_pressed() -> void:
    print("オートモード切り替え")

func _on_skip_pressed() -> void:
    print("スキップモード切り替え")

func _on_log_pressed() -> void:
    print("メッセージログを開く")

func _on_config_pressed() -> void:
    print("設定画面を開く")
```

---

## サンプル5: コレクション画面

### スクリプト例

```gdscript
# collection_screen.gd
extends Control

@onready var title_label: Label = $TitleLabel
@onready var tab_container: TabContainer = $TabContainer
@onready var completion_label: Label = $CompletionLabel

var unlocked_items: int = 15
var total_items: int = 50

func _ready() -> void:
    LocalizationManager.language_changed.connect(_update_ui_text)
    _update_ui_text(LocalizationManager.get_current_language())

func _update_ui_text(_language: String) -> void:
    title_label.text = LocalizationManager.tr("Collection.title")
    
    # タブ名を更新
    tab_container.set_tab_title(0, LocalizationManager.tr("Collection.cg_gallery"))
    tab_container.set_tab_title(1, LocalizationManager.tr("Collection.tips"))
    tab_container.set_tab_title(2, LocalizationManager.tr("Collection.music"))
    
    # 達成率を更新
    var completion_rate: float = (unlocked_items / float(total_items)) * 100.0
    completion_label.text = LocalizationManager.tr("Collection.completion_rate", [
        "%.1f" % completion_rate
    ])
```

---

## サンプル6: メッセージログ

### スクリプト例

```gdscript
# message_log.gd
extends Control

@onready var title_label: Label = $TitleLabel
@onready var log_container: VBoxContainer = $ScrollContainer/LogContainer
@onready var close_button: Button = $CloseButton

class LogEntry:
    var character_name: String
    var message: String
    var timestamp: String

var log_entries: Array[LogEntry] = []

func _ready() -> void:
    LocalizationManager.language_changed.connect(_update_ui_text)
    _update_ui_text(LocalizationManager.get_current_language())
    close_button.pressed.connect(_on_close_pressed)

func _update_ui_text(_language: String) -> void:
    title_label.text = LocalizationManager.tr("GameUI.log")
    close_button.text = LocalizationManager.tr("Common.close")
    
    # ログエントリを再描画
    _refresh_log_display()

func add_log_entry(character: String, message: String) -> void:
    var entry: LogEntry = LogEntry.new()
    entry.character_name = character
    entry.message = message
    entry.timestamp = Time.get_datetime_string_from_system()
    log_entries.append(entry)
    _refresh_log_display()

func _refresh_log_display() -> void:
    # 既存のログ表示をクリア
    for child in log_container.get_children():
        child.queue_free()
    
    # ログエントリを表示
    for entry in log_entries:
        var label: Label = Label.new()
        label.text = "[%s] %s" % [entry.character_name, entry.message]
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        log_container.add_child(label)

func _on_close_pressed() -> void:
    hide()
```

---

## サンプル7: TIPS表示

### スクリプト例

```gdscript
# tips_viewer.gd
extends Control

class TipsData:
    var id: String
    var title_key: String
    var content_key: String
    var is_unlocked: bool
    var is_new: bool

@onready var tips_list: ItemList = $HSplitContainer/TipsList
@onready var title_label: Label = $HSplitContainer/ContentPanel/TitleLabel
@onready var content_label: RichTextLabel = $HSplitContainer/ContentPanel/ContentLabel
@onready var new_badge: Label = $HSplitContainer/TipsList/NewBadge

var tips_data: Array[TipsData] = []
var selected_tips_index: int = -1

func _ready() -> void:
    LocalizationManager.language_changed.connect(_update_ui_text)
    tips_list.item_selected.connect(_on_tips_selected)
    _load_tips_data()
    _update_ui_text(LocalizationManager.get_current_language())

func _load_tips_data() -> void:
    # TIPSデータを読み込む（仮データ）
    var tips1: TipsData = TipsData.new()
    tips1.id = "tips_001"
    tips1.title_key = "Tips.example_title_1"
    tips1.content_key = "Tips.example_content_1"
    tips1.is_unlocked = true
    tips1.is_new = true
    tips_data.append(tips1)
    
    var tips2: TipsData = TipsData.new()
    tips2.id = "tips_002"
    tips2.title_key = "Tips.example_title_2"
    tips2.content_key = "Tips.example_content_2"
    tips2.is_unlocked = true
    tips2.is_new = false
    tips_data.append(tips2)

func _update_ui_text(_language: String) -> void:
    # リストを更新
    tips_list.clear()
    
    for i in range(tips_data.size()):
        var tips: TipsData = tips_data[i]
        var display_text: String
        
        if tips.is_unlocked:
            display_text = LocalizationManager.tr(tips.title_key)
            if tips.is_new:
                display_text = "[%s] %s" % [
                    LocalizationManager.tr("Tips.new"),
                    display_text
                ]
        else:
            display_text = LocalizationManager.tr("Collection.locked")
        
        tips_list.add_item(display_text)
    
    # 選択中のTIPSを再表示
    if selected_tips_index >= 0:
        _display_tips(selected_tips_index)

func _on_tips_selected(index: int) -> void:
    selected_tips_index = index
    _display_tips(index)
    
    # 新着バッジを消す
    if tips_data[index].is_new:
        tips_data[index].is_new = false
        _update_ui_text(LocalizationManager.get_current_language())

func _display_tips(index: int) -> void:
    var tips: TipsData = tips_data[index]
    
    if tips.is_unlocked:
        title_label.text = LocalizationManager.tr(tips.title_key)
        content_label.text = LocalizationManager.tr(tips.content_key)
    else:
        title_label.text = LocalizationManager.tr("Collection.locked")
        content_label.text = "???"
```

---

## サンプル8: タイトル画面（完全版）

### スクリプト例

```gdscript
# title_screen.gd
extends Control

@onready var title_label: Label = $TitleLabel
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var collection_button: Button = $VBoxContainer/CollectionButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var language_toggle: Button = $LanguageToggle

func _ready() -> void:
    LocalizationManager.language_changed.connect(_update_ui_text)
    _update_ui_text(LocalizationManager.get_current_language())
    
    # イベント接続
    start_button.pressed.connect(_on_start_pressed)
    continue_button.pressed.connect(_on_continue_pressed)
    collection_button.pressed.connect(_on_collection_pressed)
    settings_button.pressed.connect(_on_settings_pressed)
    quit_button.pressed.connect(_on_quit_pressed)
    language_toggle.pressed.connect(_on_language_toggle_pressed)
    
    # BGM再生
    AudioManager.play_bgm("title", 2.0)
    
    # セーブデータの有無で「続きから」ボタンを制御
    continue_button.disabled = not _has_save_data()

func _update_ui_text(_language: String) -> void:
    title_label.text = LocalizationManager.tr("Title.title")
    start_button.text = LocalizationManager.tr("Title.start_game")
    continue_button.text = LocalizationManager.tr("Title.continue")
    settings_button.text = LocalizationManager.tr("Title.settings")
    quit_button.text = LocalizationManager.tr("Title.quit")
    
    # 言語トグルボタンの表示
    var current_lang: String = LocalizationManager.get_current_language()
    language_toggle.text = LocalizationManager.get_current_language_name()

func _on_start_pressed() -> void:
    await AudioManager.fade_out_bgm(1.0)
    get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_continue_pressed() -> void:
    # ロード処理
    print("セーブデータをロード")

func _on_collection_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/collection.tscn")

func _on_settings_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_quit_pressed() -> void:
    get_tree().quit()

func _on_language_toggle_pressed() -> void:
    # 言語を切り替え（日本語 ⇔ 英語）
    var current: String = LocalizationManager.get_current_language()
    var new_lang: String = "en" if current == "ja" else "ja"
    LocalizationManager.change_language(new_lang)

func _has_save_data() -> bool:
    # セーブデータの存在確認
    return FileAccess.file_exists("user://save_001.dat")
```

---

## 注意点とTIPS

### 1. UI更新のタイミング

言語変更時は `language_changed` シグナルを使用してUIを更新します。

```gdscript
func _ready() -> void:
    LocalizationManager.language_changed.connect(_update_ui_text)
    _update_ui_text(LocalizationManager.get_current_language())
```

### 2. 動的なテキスト

動的に生成されるUI要素も、言語変更に対応させる必要があります。

```gdscript
func _update_ui_text(_language: String) -> void:
    # 既存の要素を更新
    for child in container.get_children():
        if child is Button:
            child.text = LocalizationManager.tr("適切なキー")
```

### 3. パフォーマンス

頻繁に呼ばれる処理では、翻訳結果をキャッシュすることを検討してください。

```gdscript
var cached_text: String = ""

func _update_text() -> void:
    var new_text: String = LocalizationManager.tr("key")
    if new_text != cached_text:
        label.text = new_text
        cached_text = new_text
```

---

これらのサンプルを参考に、プロジェクト内のすべてのUI要素を多言語対応させることができます。
