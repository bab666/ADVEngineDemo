# LocalizedUI コンポーネント使用ガイド

## 概要

インスペクターで翻訳キーを設定するだけで、自動的に多言語対応されるUIコンポーネントです。

## 利用可能なコンポーネント

- **LocalizedLabel** - 自動翻訳されるLabel
- **LocalizedButton** - 自動翻訳されるButton  
- **LocalizedRichTextLabel** - 自動翻訳されるRichTextLabel

---

## 基本的な使い方

### ステップ1: ノードを作成

通常の `Label` や `Button` の代わりに、`LocalizedLabel` や `LocalizedButton` を使用します。

**方法1: シーンツリーから追加**
1. 「+」ボタンをクリック
2. 「LocalizedButton」で検索
3. ノードを追加

**方法2: 既存ノードを変更**
1. 既存の `Button` を選択
2. 「ノードを変更」ボタン（上部のアイコン）をクリック
3. `LocalizedButton` を選択

### ステップ2: 翻訳キーを設定

インスペクターで `Translation Key` プロパティに翻訳キーを設定します。

**例:**
```
Translation Key: Title.start_game
```

### ステップ3: JSONファイルに翻訳を追加

`resources/localization/ja.json` と `en.json` に翻訳を追加します。

**ja.json:**
```json
{
  "Title": {
    "start_game": "ゲームスタート"
  }
}
```

**en.json:**
```json
{
  "Title": {
    "start_game": "Start Game"
  }
}
```

**これだけで完了！** スクリプトを書く必要はありません。

---

## 詳細な使い方

### パラメータ付き翻訳

動的な値を含むテキストの場合、`Translation Params` を使用します。

#### 例: セーブスロット表示

**JSONファイル:**
```json
{
  "Save": {
    "slot": "スロット {0}"
  }
}
```

**シーン設定:**
1. `LocalizedLabel` を作成
2. `Translation Key`: `Save.slot`
3. `Translation Params`: `[3]` （配列で指定）

**結果:**
- 日本語: "スロット 3"
- 英語: "Slot 3"

#### 例: 日付表示

**JSONファイル:**
```json
{
  "Save": {
    "save_date": "{0}年{1}月{2}日 {3}:{4}"
  }
}
```

**スクリプトから動的に設定:**
```gdscript
@onready var date_label: LocalizedLabel = $DateLabel

func _ready() -> void:
    date_label.translation_key = "Save.save_date"
    date_label.translation_params = [2025, 1, 20, 14, 30]
```

**結果:**
- 日本語: "2025年1月20日 14:30"
- 英語: "1/20/2025 14:30"

---

## エディタでのプレビュー

エディタ上では、翻訳キーが `[Title.start_game]` のように表示されます。

実際の翻訳テキストを見るには:
1. ゲームを実行する
2. または、エディタの「リモートシーン」タブで確認

---

## 実装例: タイトル画面

### シーン構成

```
TitleScreen (Control)
├── VBoxContainer
│   ├── StartButton (LocalizedButton)
│   │   └── Translation Key: "Title.start_game"
│   ├── ContinueButton (LocalizedButton)
│   │   └── Translation Key: "Title.continue"
│   ├── SettingsButton (LocalizedButton)
│   │   └── Translation Key: "Title.settings"
│   └── QuitButton (LocalizedButton)
│       └── Translation Key: "Title.quit"
```

### スクリプト

```gdscript
extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
    # 翻訳は LocalizedButton が自動処理するため不要
    # イベント接続のみ
    start_button.pressed.connect(_on_start_pressed)
    continue_button.pressed.connect(_on_continue_pressed)
    settings_button.pressed.connect(_on_settings_pressed)
    quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_continue_pressed() -> void:
    # ロード処理
    pass

func _on_settings_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_quit_pressed() -> void:
    get_tree().quit()
```

**ポイント**: 翻訳関連のコードが一切不要！

---

## 実装例: セーブスロット一覧

### シーン構成

各スロットを動的に生成する例です。

```gdscript
extends Control

const SLOT_SCENE = preload("res://scenes/ui/save_slot.tscn")

@onready var slots_container: VBoxContainer = $SlotsContainer

func _ready() -> void:
    _create_save_slots()

func _create_save_slots() -> void:
    for i in range(10):
        var slot: Control = SLOT_SCENE.instantiate()
        var slot_label: LocalizedLabel = slot.get_node("SlotLabel")
        
        # 翻訳キーとパラメータを設定
        slot_label.translation_key = "Save.slot"
        slot_label.translation_params = [i + 1]
        
        slots_container.add_child(slot)
```

---

## 言語切り替えの自動反映

LocalizedUI コンポーネントは、`LocalizationManager.language_changed` シグナルを自動的に監視します。

**言語を切り替えると、すべての LocalizedUI が自動的に更新されます。**

```gdscript
# 言語を英語に切り替え
LocalizationManager.change_language("en")

# → すべての LocalizedButton, LocalizedLabel が自動的に英語表記に！
```

---

## 既存の Button や Label から移行する方法

### 方法1: ノードタイプを変更

1. 既存の `Button` を選択
2. シーンツリー上部の「ノードを変更」アイコンをクリック
3. `LocalizedButton` を選択
4. インスペクターで `Translation Key` を設定

### 方法2: 新しく作り直す

1. 既存のノードの設定をメモ
2. 削除して `LocalizedButton` を追加
3. 設定を復元し、`Translation Key` を追加

---

## よくある質問

### Q1: エディタで翻訳が表示されない

**A:** エディタでは `[Translation.key]` のように表示されます。実際の翻訳を見るにはゲームを実行してください。

### Q2: 翻訳が反映されない

**A:** 以下を確認してください:
1. `Translation Key` が正しく設定されているか
2. JSONファイルに該当のキーが存在するか
3. JSONファイルのフォーマットが正しいか（カンマ、括弧など）

### Q3: 動的にテキストを変更したい

**A:** スクリプトから `translation_params` を変更できます:

```gdscript
@onready var score_label: LocalizedLabel = $ScoreLabel

func _ready() -> void:
    score_label.translation_key = "Game.score"
    # スコアが変わるたびに更新
    update_score(0)

func update_score(score: int) -> void:
    score_label.translation_params = [score]
```

### Q4: 一部だけ翻訳したくない

**A:** 通常の `Label` や `Button` を使用してください。LocalizedUI と通常のUIコンポーネントは共存できます。

---

## トラブルシューティング

### エラー: "Cannot access property or method"

**原因**: LocalizationManager が初期化される前にアクセスしようとしている

**解決策**: `_ready()` の最初で確認

```gdscript
func _ready() -> void:
    if not LocalizationManager:
        push_warning("LocalizationManager が見つかりません")
        return
```

### JSONパースエラー

**症状**: 翻訳が表示されず、コンソールに JSON エラー

**解決策**:
1. JSONファイルをバリデーターで確認（https://jsonlint.com/）
2. カンマや括弧の抜けをチェック
3. 文字列はダブルクォートで囲む

---

## ベストプラクティス

### 1. 翻訳キーの命名規則を統一

```
カテゴリ.具体的な内容

良い例:
- Title.start_game
- Settings.bgm_volume
- Messages.save_complete

悪い例:
- button1
- text
- msg
```

### 2. カテゴリごとにJSONを整理

```json
{
  "Title": {
    "start_game": "...",
    "continue": "..."
  },
  "Settings": {
    "language": "...",
    "volume": "..."
  }
}
```

### 3. パラメータは最小限に

複雑な文の組み立てはスクリプト側で行う方が良い場合もあります。

```gdscript
# シンプル
LocalizationManager.get_text("Messages.hello", [player_name])

# 複雑な場合はスクリプトで組み立て
var greeting = LocalizationManager.get_text("Messages.hello")
var name_part = LocalizationManager.get_text("Messages.player", [player_name])
var full_message = "%s %s" % [greeting, name_part]
```

---

## まとめ

LocalizedUI コンポーネントを使用することで:

✅ **スクリプト不要** - インスペクターとJSONファイルの編集だけで多言語対応
✅ **自動更新** - 言語切り替え時に自動的にUIが更新される
✅ **エディタフレンドリー** - `@tool` により、エディタでもプレビュー可能
✅ **既存UIとの共存** - 必要な箇所だけ LocalizedUI を使用できる

新しいラベルやボタンを追加する際は:
1. LocalizedButton / LocalizedLabel を配置
2. Translation Key を設定
3. JSONファイルに翻訳を追加

これだけで多言語対応完了です！
