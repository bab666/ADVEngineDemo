# ADVEngineDemo 多言語化システム仕様書

## 概要

ADVEngineDemoの多言語対応システムの設計と実装仕様です。
ゲーム内のすべてのUI表示テキストを、言語ファイルで管理し、実行時に切り替え可能にします。

## アーキテクチャ

### システム構成

```
LocalizationManager (Autoload Singleton)
    ├── 言語ファイル読み込み (JSON)
    ├── 翻訳テキスト取得
    ├── 言語切り替え
    └── 設定の保存/読み込み
```

### ファイル構造

```
ADVEngineDemo/
├── resources/
│   └── localization/
│       ├── ja.json        # 日本語翻訳
│       ├── en.json        # 英語翻訳
│       └── [言語].json    # 他言語（拡張用）
└── scripts/
    └── localization_manager.gd
```

---

## 翻訳ファイル形式

### JSON構造

翻訳ファイルは階層的なJSON形式で、カテゴリとキーで構成されます。

```json
{
  "_metadata": {
    "language": "Japanese",
    "language_code": "ja",
    "version": "1.0.0",
    "last_updated": "2025-01-20"
  },
  
  "Category": {
    "key": "翻訳テキスト"
  }
}
```

### ラベル命名規則

- **形式**: `Category.key`
- **カテゴリ名**: PascalCase（例: `Title`, `Settings`, `GameUI`）
- **キー名**: snake_case（例: `start_game`, `bgm_volume`）

### 例

```json
{
  "Title": {
    "start_game": "ゲームスタート",
    "settings": "設定"
  },
  
  "Settings": {
    "bgm_volume": "BGM音量",
    "text_speed": "テキスト速度"
  }
}
```

---

## LocalizationManager API

### 基本的な使用方法

#### 翻訳テキストの取得

```gdscript
# 基本的な翻訳
var text: String = LocalizationManager.tr("Title.start_game")
# -> "ゲームスタート" (日本語) or "Start Game" (英語)

# パラメータ付き翻訳
var text: String = LocalizationManager.tr("Save.slot", [1])
# -> "スロット 1" or "Slot 1"

var text: String = LocalizationManager.tr("Common.page", [3, 10])
# -> "ページ 3/10" or "Page 3/10"
```

#### 言語の変更

```gdscript
# 言語を英語に変更
LocalizationManager.change_language("en")

# 現在の言語を取得
var current: String = LocalizationManager.get_current_language()
# -> "ja" or "en"

# 言語の表示名を取得
var name: String = LocalizationManager.get_current_language_name()
# -> "Japanese" or "English"
```

#### 言語変更の検知

```gdscript
func _ready() -> void:
    # 言語変更時のコールバック登録
    LocalizationManager.language_changed.connect(_on_language_changed)

func _on_language_changed(new_language: String) -> void:
    print("言語が変更されました: ", new_language)
    _update_ui_text()
```

### 主要なメソッド

#### `tr(key: String, params: Array = []) -> String`

翻訳キーからテキストを取得します。

- **引数**:
  - `key`: 翻訳キー（形式: "Category.key"）
  - `params`: パラメータ配列（オプション）
- **戻り値**: 翻訳されたテキスト
- **例**:
  ```gdscript
  LocalizationManager.tr("Title.start_game")
  LocalizationManager.tr("Save.slot", [5])
  ```

#### `change_language(language_code: String) -> bool`

言語を変更します。

- **引数**:
  - `language_code`: 言語コード（"ja", "en"など）
- **戻り値**: 成功時 `true`、失敗時 `false`
- **副作用**: `language_changed` シグナルを発行

#### `get_current_language() -> String`

現在の言語コードを取得します。

#### `get_supported_languages() -> Array[String]`

サポートされている言語コードのリストを取得します。

#### `get_language_names() -> Dictionary`

言語コードと表示名の辞書を取得します。

```gdscript
var names: Dictionary = LocalizationManager.get_language_names()
# -> {"ja": "Japanese", "en": "English"}
```

---

## UI実装パターン

### パターン1: シーン読み込み時に翻訳

```gdscript
extends Control

@onready var title_label: Label = $TitleLabel
@onready var start_button: Button = $StartButton

func _ready() -> void:
    # UI初期化
    _update_ui_text(LocalizationManager.get_current_language())
    
    # 言語変更を監視
    LocalizationManager.language_changed.connect(_update_ui_text)

func _update_ui_text(_language: String) -> void:
    title_label.text = LocalizationManager.tr("Title.title")
    start_button.text = LocalizationManager.tr("Title.start_game")
```

### パターン2: 動的な翻訳

```gdscript
func display_message(slot_number: int) -> void:
    var message: String = LocalizationManager.tr("Save.slot", [slot_number])
    $MessageLabel.text = message
```

### パターン3: メニューでの言語切り替え

```gdscript
extends Control

@onready var language_option: OptionButton = $LanguageOption

func _ready() -> void:
    _setup_language_options()

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
    
    language_option.item_selected.connect(_on_language_selected)

func _on_language_selected(index: int) -> void:
    var lang_code: String = language_option.get_item_metadata(index)
    LocalizationManager.change_language(lang_code)
```

---

## 新しい翻訳カテゴリの追加

### 手順

1. **翻訳キーの設計**
   - カテゴリ名とキー名を決定
   - 例: `Battle.attack`, `Inventory.use_item`

2. **すべての言語ファイルに追加**
   - `ja.json`, `en.json` など、すべての言語ファイルに同じ構造を追加

3. **スクリプトで使用**
   ```gdscript
   var text: String = LocalizationManager.tr("Battle.attack")
   ```

### 例: 新しいカテゴリ「Inventory」の追加

**ja.json**
```json
{
  "Inventory": {
    "title": "アイテム",
    "use_item": "使う",
    "discard": "捨てる",
    "quantity": "所持数: {0}"
  }
}
```

**en.json**
```json
{
  "Inventory": {
    "title": "Items",
    "use_item": "Use",
    "discard": "Discard",
    "quantity": "Qty: {0}"
  }
}
```

**スクリプト**
```gdscript
label.text = LocalizationManager.tr("Inventory.title")
button.text = LocalizationManager.tr("Inventory.use_item")
quantity_label.text = LocalizationManager.tr("Inventory.quantity", [item_count])
```

---

## 新しい言語の追加

### 手順

1. **言語ファイルの作成**
   - `resources/localization/[言語コード].json` を作成
   - 例: `zh.json` (中国語), `ko.json` (韓国語)

2. **LocalizationManagerの更新**
   ```gdscript
   const SUPPORTED_LANGUAGES: Array[String] = ["ja", "en", "zh", "ko"]
   ```

3. **翻訳内容の追加**
   - 既存の日本語・英語ファイルを参考に、すべてのキーを翻訳

### 例: 中国語の追加

**zh.json**
```json
{
  "_metadata": {
    "language": "中文",
    "language_code": "zh",
    "version": "1.0.0"
  },
  
  "Title": {
    "title": "标题",
    "start_game": "开始游戏",
    "settings": "设置"
  }
}
```

**localization_manager.gd**
```gdscript
const SUPPORTED_LANGUAGES: Array[String] = ["ja", "en", "zh"]
```

---

## パラメータ置換

### 基本的な使い方

翻訳テキスト内で `{0}`, `{1}`, `{2}` などのプレースホルダーを使用できます。

```json
{
  "Save": {
    "slot": "スロット {0}",
    "save_date": "{0}年{1}月{2}日 {3}:{4}"
  }
}
```

```gdscript
# 単一パラメータ
var text1: String = LocalizationManager.tr("Save.slot", [3])
# -> "スロット 3"

# 複数パラメータ
var text2: String = LocalizationManager.tr("Save.save_date", [2025, 1, 20, 14, 30])
# -> "2025年1月20日 14:30"
```

### 注意点

- パラメータの順序は言語によって異なる場合があります
- 各言語ファイルで適切な順序を設定してください

**日本語**: `{0}年{1}月{2}日`
**英語**: `{1}/{2}/{0}` (月/日/年)

---

## フォールバック機能

### 仕様

1. **現在の言語で翻訳が見つからない場合**
   - デフォルト言語（日本語）の翻訳を使用

2. **デフォルト言語でも見つからない場合**
   - キーをそのまま返す
   - コンソールに警告を出力

### 例

```gdscript
# 英語に設定されているが、"NewFeature.button" が en.json に存在しない場合
var text: String = LocalizationManager.tr("NewFeature.button")
# -> ja.json の "NewFeature.button" を使用
# -> それも無い場合は "NewFeature.button" をそのまま返す
```

---

## ベストプラクティス

### 1. 一貫したキー命名

- カテゴリは機能や画面単位で分ける
- キーは具体的かつ一意にする

**良い例**:
```
Title.start_game
Title.continue
Settings.bgm_volume
```

**悪い例**:
```
button1
text
menu_item
```

### 2. パラメータの適切な使用

- 動的な値（数値、名前など）はパラメータで渡す
- 静的なテキストは翻訳ファイルに含める

```gdscript
# 良い
LocalizationManager.tr("Messages.items_obtained", [item_name, count])

# 悪い（item_name を翻訳キーにしている）
LocalizationManager.tr("Messages." + item_name + "_obtained")
```

### 3. UI更新の最適化

- 言語変更時のコールバックを活用
- 必要な箇所のみ更新する

```gdscript
func _ready() -> void:
    LocalizationManager.language_changed.connect(_update_ui)

func _update_ui(_lang: String) -> void:
    # 必要な箇所のみ更新
    title_label.text = LocalizationManager.tr("Title.title")
```

---

## デバッグ機能

### 利用可能なカテゴリの確認

```gdscript
var categories: Array = LocalizationManager.get_all_categories()
print("利用可能なカテゴリ: ", categories)
```

### カテゴリ内のキー一覧の確認

```gdscript
var keys: Array = LocalizationManager.get_category_keys("Title")
print("Titleカテゴリのキー: ", keys)
```

---

## 設定の保存

### 仕様

- 選択された言語は `user://settings.cfg` に保存されます
- ゲーム再起動時に前回の言語設定が復元されます

### ConfigFile形式

```ini
[general]
language="ja"
```

---

## トラブルシューティング

### 翻訳が表示されない

1. **翻訳キーが正しいか確認**
   ```gdscript
   # 正しい
   LocalizationManager.tr("Title.start_game")
   
   # 間違い（スペルミス）
   LocalizationManager.tr("Title.start_gane")
   ```

2. **言語ファイルにキーが存在するか確認**
   - `resources/localization/ja.json` を開く
   - 該当のカテゴリとキーが存在するか確認

3. **コンソールの警告を確認**
   ```
   無効な翻訳キー: Title.start_gane
   翻訳が見つかりません: Title.start_game
   ```

### 言語が切り替わらない

1. **サポート言語リストを確認**
   ```gdscript
   const SUPPORTED_LANGUAGES: Array[String] = ["ja", "en"]
   ```

2. **言語ファイルが存在するか確認**
   - `resources/localization/en.json` が存在するか

3. **language_changed シグナルが接続されているか確認**
   ```gdscript
   LocalizationManager.language_changed.connect(_update_ui)
   ```

---

## まとめ

このシステムにより、ADVEngineDemoは以下の機能を実現します:

- ✅ UIテキストの完全な多言語対応
- ✅ 実行時の言語切り替え
- ✅ 設定の永続化
- ✅ フォールバック機能による安全性
- ✅ 拡張性の高い設計

新しい言語や翻訳テキストの追加も容易で、将来的な拡張に対応できます。
