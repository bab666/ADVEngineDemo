# セーブ・ロードシステム完全仕様書

## 概要

ADVEngineDemoに実装されたセーブ・ロードシステムの完全な仕様書です。

### 主要機能

1. **スナップショット方式**: 全システムの状態を一度に保存
2. **マルチスロット対応**: 通常セーブ99スロット + オートセーブ + クイックセーブ
3. **完全な状態復元**: シナリオ位置、変数、キャラクター、オーディオ、カメラ
4. **メタデータ管理**: 日時、チャプター、プレイ時間（将来実装）
5. **拡張性**: サムネイル、クラウドセーブなどへの対応が容易

---

## システムアーキテクチャ

### 保存される情報

```
セーブデータ
├── version (バージョン情報)
├── metadata (メタデータ)
│   ├── save_date
│   ├── timestamp
│   ├── scenario_file
│   ├── chapter
│   └── play_time
├── scenario (シナリオ状態)
│   ├── current_file
│   ├── current_line
│   └── call_stack
├── variables (変数)
│   ├── セーブ変数
│   └── (システム変数は別管理)
├── characters (キャラクター表示)
│   └── [char_id]
│       ├── expression
│       ├── position
│       ├── scale
│       └── ...
├── audio (オーディオ)
│   ├── current_bgm
│   ├── playback_position
│   └── volume settings
└── camera (カメラ)
    ├── position
    ├── zoom
    └── rotation
```

### ファイル構造

```
user://saves/
├── autosave.sav        (スロット0: オートセーブ)
├── quicksave.sav       (スロット-1: クイックセーブ)
├── save_001.sav        (通常セーブ スロット1)
├── save_002.sav        (通常セーブ スロット2)
└── ...
    save_099.sav        (通常セーブ スロット99)
```

---

## セーブコマンド

### @save

ゲームの現在状態をセーブします。

**書式:**
```
@save [slot_id]
```

**パラメータ:**
- `slot_id`: セーブスロットID（省略時はオートセーブ）
  - 省略: オートセーブ（スロット0）
  - `1~99`: 通常セーブスロット
  - `quick`: クイックセーブ

**例:**
```
# オートセーブ
@save

# スロット1にセーブ
@save 1

# クイックセーブ
@save quick
```

### セーブされるタイミング

- `@save`コマンド実行時
- セーブ画面でユーザーが保存を選択した時（将来実装）
- チャプター終了時の自動セーブ（将来実装）

---

## ロードコマンド

### @load

セーブデータからゲームを復元します。

**書式:**
```
@load [slot_id]
```

**パラメータ:**
- `slot_id`: ロードするセーブスロットID（省略時はオートセーブ）

**例:**
```
# オートセーブからロード
@load

# スロット1からロード
@load 1

# クイックロード
@load quick
```

### ロード時の動作

1. **状態の復元順序**:
   1. 変数
   2. カメラ
   3. オーディオ
   4. キャラクター
   5. シナリオ（最後）

2. **シナリオの再開**:
   - セーブした行の**次の行**から再開
   - コールスタックも復元される

---

## スクリプトからの使用

### セーブ

```gdscript
# GameManager経由
game_manager.save_manager.save_game(1)  # スロット1にセーブ

# オートセーブ
game_manager.save_manager.save_game(SaveManager.SLOT_AUTO_SAVE)

# クイックセーブ
game_manager.save_manager.save_game(SaveManager.SLOT_QUICK_SAVE)
```

### ロード

```gdscript
# スロット1からロード
game_manager.save_manager.load_game(1)

# オートロード
game_manager.save_manager.load_game(SaveManager.SLOT_AUTO_SAVE)
```

### セーブスロット情報の取得

```gdscript
# 特定のスロット情報
var slot_info: Dictionary = save_manager.get_slot_info(1)
print(slot_info["save_date"])
print(slot_info["chapter"])

# すべての通常セーブスロット
var all_slots: Array[Dictionary] = save_manager.get_all_slots()
for slot in all_slots:
    print("スロット%d: %s" % [slot["slot_id"], slot["save_date"]])

# スロットの存在チェック
if save_manager.has_save(1):
    print("スロット1にセーブデータがあります")
```

### セーブデータの削除

```gdscript
# スロット1を削除
save_manager.delete_save(1)
```

---

## セーブデータ形式

### JSON形式

セーブデータはJSON形式で保存されます（人間が読める形式）。

**例:**
```json
{
	"version": "1.0.0",
	"metadata": {
		"slot_id": 1,
		"save_date": "2025-01-20 14:30:00",
		"timestamp": 1705741800,
		"scenario_file": "res://resources/scenarios/demo.txt",
		"scenario_line": 42,
		"chapter": 2,
		"play_time": 0
	},
	"scenario": {
		"current_file": "res://resources/scenarios/demo.txt",
		"current_line": 42,
		"call_stack": []
	},
	"variables": {
		"count": 10,
		"flag": true,
		"route": "alice"
	},
	"characters": {
		"ai": {
			"expression": "normal",
			"pos_mode": "auto",
			"scale": 1.0,
			...
		}
	},
	"audio": {
		"current_bgm": "peaceful_day",
		"is_playing": true,
		"playback_position": 45.2,
		"bgm_volume": 0.0,
		"se_volume": 0.0
	},
	"camera": {
		"position": {"x": 0, "y": 0},
		"zoom": {"x": 1, "y": 1},
		"rotation": 0
	}
}
```

---

## シグナル

SaveManagerは以下のシグナルを発行します。

### save_completed(slot_id: int)

セーブが正常に完了した時。

```gdscript
save_manager.save_completed.connect(func(slot_id):
    print("セーブ完了: スロット%d" % slot_id)
)
```

### load_completed(slot_id: int)

ロードが正常に完了した時。

```gdscript
save_manager.load_completed.connect(func(slot_id):
    print("ロード完了: スロット%d" % slot_id)
)
```

### save_failed(slot_id: int, error: String)

セーブが失敗した時。

```gdscript
save_manager.save_failed.connect(func(slot_id, error):
    print("セーブ失敗: スロット%d - %s" % [slot_id, error])
)
```

### load_failed(slot_id: int, error: String)

ロードが失敗した時。

```gdscript
save_manager.load_failed.connect(func(slot_id, error):
    print("ロード失敗: スロット%d - %s" % [slot_id, error])
)
```

---

## 実装例

### 例1: チャプター終了時の自動セーブ

```
# チャプター1終了
@set chapter=2
ai: チャプター1が終了しました。

# 自動セーブ
@save

ai: チャプター2を開始します。
```

### 例2: セーブポイント

```
ai: セーブポイントです。
@save

ai: ここから先は危険な戦闘があります。
```

### 例3: クイックセーブ・ロード

```
# シナリオ内
ai: クイックセーブしますか？
@choice
    はい|いいえ
@choice_result result

@if result == 0
    @save quick
    ai: クイックセーブしました。
@endif
```

---

## セーブ画面の実装例

将来実装するセーブ画面のサンプルコード。

```gdscript
extends Control

@onready var slots_container: VBoxContainer = $SlotsContainer
@onready var save_manager: SaveManager = get_node("/root/GameManager/SaveManager")

func _ready() -> void:
    _create_save_slots()

func _create_save_slots() -> void:
    for i in range(1, 10):  # スロット1~9
        var slot_button: Button = Button.new()
        slot_button.text = _get_slot_text(i)
        slot_button.pressed.connect(_on_slot_pressed.bind(i))
        slots_container.add_child(slot_button)

func _get_slot_text(slot_id: int) -> String:
    if save_manager.has_save(slot_id):
        var info: Dictionary = save_manager.get_slot_info(slot_id)
        return "スロット%d: %s" % [slot_id, info.get("save_date", "")]
    else:
        return "スロット%d: 空き" % slot_id

func _on_slot_pressed(slot_id: int) -> void:
    save_manager.save_game(slot_id)
    _refresh_slots()

func _refresh_slots() -> void:
    for i in range(slots_container.get_child_count()):
        var button: Button = slots_container.get_child(i)
        button.text = _get_slot_text(i + 1)
```

---

## バージョン管理

### バージョン互換性

セーブデータには`version`フィールドがあり、互換性チェックに使用されます。

```gdscript
const SAVE_VERSION: String = "1.0.0"

func _is_compatible_version(saved_version: String) -> bool:
    var current_parts: PackedStringArray = SAVE_VERSION.split(".")
    var saved_parts: PackedStringArray = saved_version.split(".")
    
    # メジャーバージョンが同じなら互換性あり
    return current_parts[0] == saved_parts[0]
```

### バージョンアップ時の対応

メジャーバージョンを上げた場合、古いセーブデータとの互換性が失われます。

**マイナー・パッチバージョンアップ**: 互換性維持
**メジャーバージョンアップ**: 互換性なし

---

## エラーハンドリング

### よくあるエラーと対処法

#### エラー: "セーブデータの読み込みに失敗"

**原因**:
- ファイルが存在しない
- ファイルが破損している
- JSONパースエラー

**対処法**:
```gdscript
if not save_manager.has_save(slot_id):
    print("セーブデータがありません")
    return

if not save_manager.load_game(slot_id):
    print("ロードに失敗しました")
```

#### エラー: "互換性のないセーブデータバージョン"

**原因**: ゲームのバージョンとセーブデータのバージョンが異なる

**対処法**: 新しいゲームを開始するか、互換性のあるバージョンでプレイ

---

## ベストプラクティス

### 1. 定期的なオートセーブ

```
# 重要なシーン前
@save

# チャプター終了時
@set chapter=chapter+1
@save
```

### 2. ユーザーにセーブを促す

```
ai: セーブしますか？
@choice
    セーブする|スキップ
@choice_result result

@if result == 0
    @save 1
@endif
```

### 3. クイックセーブ/ロードのショートカット

```gdscript
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("quick_save"):
        save_manager.save_game(SaveManager.SLOT_QUICK_SAVE)
    
    if event.is_action_pressed("quick_load"):
        save_manager.load_game(SaveManager.SLOT_QUICK_SAVE)
```

---

## 将来の拡張

### サムネイル対応

```gdscript
# セーブ時にスクリーンショットを撮影
var viewport: Viewport = get_viewport()
var image: Image = viewport.get_texture().get_image()
image.save_png("user://saves/save_001_thumb.png")
```

### クラウドセーブ

セーブデータをクラウドにアップロード・ダウンロードする機能。

### 圧縮保存

大きなセーブデータを圧縮して保存容量を削減。

```gdscript
# 圧縮保存
var compressed: PackedByteArray = json_string.to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP)
file.store_buffer(compressed)
```

---

## トラブルシューティング

### Q1: ロード後、キャラクターが表示されない

**原因**: CharacterDisplay.load_state()が正しく呼ばれていない

**解決策**: 
1. SaveManagerの復元順序を確認
2. CharacterDisplayのactive_character_statesが正しく保存されているか確認

### Q2: BGMが途中から再生されない

**原因**: 再生位置の復元が失敗している

**解決策**:
```gdscript
# AudioManager.load_state()でseek()を呼ぶ前に少し待機
await get_tree().create_timer(0.05).timeout
bgm_player.seek(position)
```

### Q3: 変数が復元されない

**原因**: VariableManagerの統合が不完全

**解決策**: SaveManagerでVariableManager.get_save_data()を呼んでいるか確認

---

## まとめ

セーブ・ロードシステムにより:

✅ **完全な状態保存** - すべてのシステムの状態を保存
✅ **柔軟なスロット管理** - 通常・オート・クイックセーブ
✅ **拡張性** - サムネイル、クラウドセーブなどに対応可能
✅ **堅牢性** - エラーハンドリング、バージョン管理
✅ **使いやすさ** - シンプルなコマンド、シグナル

---

## 関連ファイル

- `scripts/save_manager.gd` - セーブ・ロード管理
- `scripts/commands/save_command.gd` - セーブコマンド
- `scripts/commands/load_command.gd` - ロードコマンド
- `resources/scenarios/save_test.txt` - テストシナリオ
