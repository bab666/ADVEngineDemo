# シナリオ内翻訳ラベル機能

## 概要

シナリオテキスト内で `{T_key}` 形式の翻訳ラベルを使用できます。カテゴリは省略可能で、BBCode装飾も有効です。

---

## 基本的な使い方

### 1. JSONファイルに翻訳を定義

**ja.json:**
```json
{
  "Scenario": {
    "greeting": "こんにちは！",
    "player_name": "主人公",
    "tips1": "TIPS：<color=cyan>これはサンプルです</color>"
  }
}
```

**en.json:**
```json
{
  "Scenario": {
    "greeting": "Hello!",
    "player_name": "Hero",
    "tips1": "TIPS: <color=cyan>This is a sample</color>"
  }
}
```

### 2. シナリオで使用

```
ai: {T_greeting}
ai: 私の名前は{T_player_name}です。
ai: {T_tips1}
```

### 3. 実行結果

**日本語:**
```
ai: こんにちは！
ai: 私の名前は主人公です。
ai: TIPS：これはサンプルです（青色）
```

**英語:**
```
ai: Hello!
ai: My name is Hero.
ai: TIPS: This is a sample (cyan)
```

---

## 機能詳細

### カテゴリの省略

`{T_key}` 形式では、カテゴリを省略できます。システムが全カテゴリを自動検索します。

**推奨:**
```
{T_greeting}          ← カテゴリ省略（推奨）
```

**非推奨（従来の方法）:**
```
LocalizationManager.get_text("Scenario.greeting")  ← スクリプトでの使用
```

### BBCode装飾対応

翻訳テキスト内でBBCodeタグが使えます。

**サポートされる主なタグ:**
- `<b>太字</b>`
- `<i>斜体</i>`
- `<color=red>赤文字</color>`
- `<color=#FF0000>赤文字（16進数）</color>`
- `<font_size=24>サイズ変更</font_size>`
- `<u>下線</u>`
- `<s>取り消し線</s>`
- `<br>` - 改行

**例:**
```json
{
  "Scenario": {
    "decorated": "これは<b>太字</b>で、<color=red>赤色</color>です。"
  }
}
```

シナリオ:
```
ai: {T_decorated}
```

結果:
```
ai: これは太字で、赤色です。
```

---

## 実装例

### 基本パターン

**シナリオファイル (translation_test.txt):**
```
@bg room
@chara ai normal

ai: {T_greeting}
ai: 私は{T_player_name}です。
ai: {T_tips1}
```

### 複数ラベルの組み合わせ

```
ai: {T_greeting} 私は{T_player_name}と言います。{T_farewell}
```

### 通常テキストとの混在

```
ai: こんにちは、世界！私の名前は{T_player_name}です。
ai: {T_greeting} よろしくお願いします。
```

### キャラクター名でも使用可能

```
{T_narrator}: これはナレーションです。
{T_system_voice}: システムメッセージ
{T_player_name}: プレイヤーのセリフ
```

---

## 翻訳ファイル自動生成ツール

### 使い方

1. **プラグインを有効化**
   ```
   プロジェクト → プロジェクト設定 → プラグイン
   → "Localization Tools" を有効化
   ```

2. **日本語ファイル (ja.json) を編集**
   ```json
   {
     "Scenario": {
       "new_key": "新しいテキスト"
     }
   }
   ```

3. **他言語ファイルを自動生成**
   ```
   右側のドック → "Localization Tools" タブ
   → 生成する言語を選択（チェックボックス）
   → 「翻訳ファイルを生成」ボタンをクリック
   ```

4. **生成されたファイルを確認**
   ```
   resources/localization/en.json
   resources/localization/zh.json
   resources/localization/ko.json
   ...
   ```

### 自動生成の仕様

- **新規キー**: `[TO TRANSLATE]` プレフィックス付きで日本語をプレースホルダーとして挿入
- **既存キー**: 既存の翻訳を保持（上書きしない）
- **メタデータ**: 自動的に言語名と更新日時を設定

**生成例 (en.json):**
```json
{
  "_metadata": {
    "language": "英語 (English)",
    "language_code": "en",
    "version": "1.0.0",
    "last_updated": "2025-01-20T14:30:00"
  },
  
  "Scenario": {
    "greeting": "Hello!",
    "new_key": "[TO TRANSLATE] 新しいテキスト"
  }
}
```

### 翻訳作業のワークフロー

1. **ja.json に新しいキーを追加**
   ```json
   {
     "Scenario": {
       "new_message": "これは新しいメッセージです"
     }
   }
   ```

2. **自動生成ツールで他言語ファイルを更新**
   ```
   「翻訳ファイルを生成」ボタンをクリック
   ```

3. **生成されたファイルで `[TO TRANSLATE]` を検索**
   ```
   [TO TRANSLATE] これは新しいメッセージです
   ```

4. **適切な翻訳に置き換え**
   ```json
   {
     "Scenario": {
       "new_message": "This is a new message"
     }
   }
   ```

---

## サポートされる言語

現在、以下の言語ファイルを自動生成できます:

- 英語 (en)
- 中国語 (zh)
- 韓国語 (ko)
- スペイン語 (es)
- フランス語 (fr)
- ドイツ語 (de)

**カスタム言語の追加:**

`localization_panel.gd` を編集:
```gdscript
const TARGET_LANGUAGES: Array[String] = ["en", "zh", "ko", "新しい言語コード"]
```

---

## よくある使用例

### TIPS表示

```json
{
  "Scenario": {
    "tips_magic": "TIPS：<color=cyan>魔法は3種類あります</color>",
    "tips_combat": "TIPS：<b>戦闘は自動進行です</b>"
  }
}
```

```
ai: {T_tips_magic}
ai: {T_tips_combat}
```

### システムメッセージ

```json
{
  "Scenario": {
    "narrator": "ナレーション",
    "system": "システム",
    "loading": "読み込み中..."
  }
}
```

```
{T_narrator}: 物語は始まった...
{T_system}: {T_loading}
```

### キャラクター名

```json
{
  "Scenario": {
    "hero": "主人公",
    "mysterious_person": "謎の人物"
  }
}
```

```
{T_hero}: こんにちは。
{T_mysterious_person}: ...
```

---

## トラブルシューティング

### Q1: 翻訳ラベルがそのまま表示される

**原因**: キーが見つからない

**確認点**:
1. JSONファイルにキーが存在するか
2. スペルミス
3. JSONのフォーマットエラー

**解決策**:
```
コンソールログを確認:
"カテゴリ省略検索で翻訳が見つかりません: key_name"
```

### Q2: BBCodeが効かない

**原因**: RichTextLabelでbbcode_enabledが無効

**解決策**:
MessageWindowでは自動的に有効化されています。カスタムウィンドウを使う場合:
```gdscript
text_label.bbcode_enabled = true
```

### Q3: 改行が効かない

**解決策**:
BBCodeタグを使用:
```json
{
  "text": "1行目<br>2行目<br>3行目"
}
```

または通常の改行:
```json
{
  "text": "1行目\n2行目\n3行目"
}
```

### Q4: 自動生成ツールが動作しない

**確認点**:
1. プラグインが有効化されているか
2. ja.json が存在するか
3. ja.json のJSONフォーマットが正しいか

**解決策**:
JSONLintなどでバリデーション: https://jsonlint.com/

---

## ベストプラクティス

### 1. カテゴリ分けの推奨

```json
{
  "Scenario": {
    // シナリオ内で使うテキスト
  },
  "Characters": {
    // キャラクター名
  },
  "Tips": {
    // TIPSテキスト
  },
  "System": {
    // システムメッセージ
  }
}
```

### 2. キー命名規則

```
良い例:
- greeting_morning
- farewell_evening
- tips_combat_basic

悪い例:
- text1
- msg
- a
```

### 3. BBCodeの適度な使用

```json
{
  "good": "重要な<b>単語</b>だけ装飾",
  "bad": "<color=red><b><font_size=24>全部装飾</font_size></b></color>"
}
```

---

## まとめ

シナリオ内翻訳ラベル機能により:

✅ **シナリオファイルを多言語対応**
- `{T_key}` で簡単に翻訳参照

✅ **BBCode装飾対応**
- リッチな表現が可能

✅ **カテゴリ省略可能**
- シンプルな記述

✅ **自動生成ツール**
- 翻訳ファイルの管理が容易

---

## 関連ファイル

- `scripts/localization_manager.gd` - コア機能
- `scripts/message_window.gd` - シナリオパース処理
- `addons/localization_tools/` - 自動生成プラグイン
- `resources/scenarios/translation_test.txt` - サンプルシナリオ
