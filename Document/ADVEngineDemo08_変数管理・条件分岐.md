# 変数管理システム・条件分岐仕様書

## 概要

ADVEngineDemoに変数管理システムと条件分岐機能を実装しました。

### 主要機能

1. **変数管理**
   - セーブ変数（セーブデータごと）
   - システム変数（全セーブデータ共通）

2. **条件分岐**
   - `@if` / `@elif` / `@else` / `@endif`
   - 比較演算、論理演算対応

3. **式評価**
   - 算術式、比較式、論理式

---

## 変数の種類

### セーブ変数（デフォルト）

セーブデータごとに保存される変数。ゲームの進行状況、フラグ、選択肢の結果などに使用。

**設定:**
```
@set count=10
@set flag=true
@set route="alice_route"
```

**参照:**
```
@if count > 5
@if flag == true
```

### システム変数

全セーブデータで共有される変数。`s$` プレフィックスを使用。設定、プレイ回数、実績などに使用。

**設定:**
```
@set s$play_count=1
@set s$language="ja"
@set s$volume=80
```

**参照:**
```
@if s$play_count > 1
```

---

## @set コマンド

### 基本構文

```
@set 変数名=値
```

### サポートされる値の型

#### 整数
```
@set count=10
@set level=5
@set score=100
```

#### 浮動小数点数
```
@set health=85.5
@set temperature=36.5
```

#### 真偽値
```
@set flag=true
@set is_completed=false
```

#### 文字列
```
@set name="Alice"
@set route="good_ending"
@set message='こんにちは'
```

### システム変数の設定

```
@set s$play_count=1
@set s$unlocked_cg_001=true
```

### 算術式

```
@set result=10+5
@set score=count*2
@set half=total/2
```

### 変数参照

```
@set new_count=$count
@set backup=$old_value
```

---

## 条件分岐

### @if / @endif

基本的な条件分岐。

```
@if 条件式
    ... (条件が真の場合に実行)
@endif
```

**例:**
```
@if count > 10
    ai: カウントが10より大きいです
@endif
```

### @if / @else / @endif

条件が偽の場合の処理を記述。

```
@if 条件式
    ... (真の場合)
@else
    ... (偽の場合)
@endif
```

**例:**
```
@if flag == true
    ai: フラグが立っています
@else
    ai: フラグが立っていません
@endif
```

### @if / @elif / @else / @endif

複数の条件を評価。

```
@if 条件式1
    ... (条件1が真)
@elif 条件式2
    ... (条件2が真)
@elif 条件式3
    ... (条件3が真)
@else
    ... (すべて偽)
@endif
```

**例:**
```
@if score >= 90
    ai: 評価：優秀
@elif score >= 70
    ai: 評価：良好
@elif score >= 50
    ai: 評価：普通
@else
    ai: 評価：要努力
@endif
```

---

## 条件式

### 比較演算子

| 演算子 | 意味 | 例 |
|--------|------|-----|
| `==` | 等しい | `count == 10` |
| `!=` | 等しくない | `flag != true` |
| `>` | より大きい | `score > 50` |
| `<` | より小さい | `level < 5` |
| `>=` | 以上 | `age >= 18` |
| `<=` | 以下 | `count <= 100` |

**例:**
```
@if count == 10
@if score > 50
@if level >= 5
@if name != "Alice"
```

### 論理演算子

| 演算子 | 意味 | 例 |
|--------|------|-----|
| `and` | かつ | `age >= 18 and has_license == true` |
| `or` | または | `route == "a" or route == "b"` |
| `not` | 否定 | `not flag` |

**例:**
```
@if age >= 18 and has_license == true
    ai: 運転できます
@endif

@if route == "alice" or route == "bob"
    ai: メインルートです
@endif

@if not completed
    ai: まだ完了していません
@endif
```

### 複合条件

```
@if (age >= 18 and has_license == true) or is_vip == true
    ai: 入場できます
@endif
```

---

## ネストした条件分岐

条件分岐は入れ子にできます。

```
@if level > 0
    ai: レベルチェック開始
    
    @if level >= 10
        ai: レベル：上級
    @elif level >= 5
        ai: レベル：中級
    @else
        ai: レベル：初級
    @endif
    
    ai: レベルチェック終了
@endif
```

---

## 変数の参照

### シナリオ内での参照

変数の値はシナリオテキスト内では直接参照できません。条件分岐で使用してください。

**NG（動作しない）:**
```
ai: あなたのスコアは$scoreです  <- 直接参照は不可
```

**OK（条件分岐で使用）:**
```
@if score >= 100
    ai: パーフェクトスコアです！
@elif score >= 50
    ai: 良いスコアです
@else
    ai: もう少し頑張りましょう
@endif
```

### スクリプトからの参照

```gdscript
# 値を取得
var count: int = VariableManager.get_variable("count")
var play_count: int = VariableManager.get_variable("play_count", true)  # システム変数

# 値を設定
VariableManager.set_variable("score", 100)
VariableManager.set_variable("language", "en", true)  # システム変数
```

---

## 変数のスコープと永続化

### セーブ変数

- **スコープ**: セーブデータごと
- **永続化**: セーブデータに保存
- **用途**: ゲーム進行、フラグ、選択結果

```
@set chapter=2
@set met_alice=true
@set route="good_ending"
```

### システム変数

- **スコープ**: 全セーブデータ共通
- **永続化**: `user://system_variables.cfg` に自動保存
- **用途**: 設定、プレイ回数、実績

```
@set s$play_count=5
@set s$unlocked_gallery_01=true
@set s$bgm_volume=80
```

---

## 実装例

### フラグ管理

```
# イベント発生
@set event_001_completed=true

# フラグチェック
@if event_001_completed == true
    ai: そのイベントはもう見ました
@else
    ai: 初めてのイベントです
@endif
```

### ルート分岐

```
# 選択肢の結果
@set route="alice"

# ルートに応じた分岐
@if route == "alice"
    @jump alice_route.start
@elif route == "bob"
    @jump bob_route.start
@else
    @jump common_route.start
@endif
```

### カウンター

```
# カウンターを初期化
@set visit_count=0

# カウントアップ
@set visit_count=1
@set visit_count=2

# カウントに応じた分岐
@if visit_count == 1
    ai: 初めまして
@elif visit_count < 5
    ai: また来てくれたんですね
@else
    ai: 常連さんですね！
@endif
```

### プレイ回数管理

```
# 初回起動時
@if s$play_count == 0
    ai: ようこそ！初めてのプレイですね
    @set s$play_count=1
@else
    ai: おかえりなさい
@endif
```

### 実績・コレクション

```
# CG解放
@set cg_001_unlocked=true
@set s$total_cg_unlocked=5

# TIPS解放
@set tips_magic_unlocked=true
```

---

## セーブ/ロード対応

### セーブデータの保存

```gdscript
# セーブ変数を取得
var save_data: Dictionary = VariableManager.get_save_data()

# セーブファイルに書き込み
# ... (save_dataをJSONなどで保存)
```

### セーブデータの読み込み

```gdscript
# セーブファイルから読み込み
var save_data: Dictionary = # ... (JSONなどから読み込み)

# セーブ変数を復元
VariableManager.load_save_data(save_data)
```

---

## デバッグ機能

### 変数の一覧表示

```gdscript
# セーブ変数の一覧
var save_vars: Dictionary = VariableManager.get_all_variables(false)
print(save_vars)

# システム変数の一覧
var system_vars: Dictionary = VariableManager.get_all_variables(true)
print(system_vars)
```

### 変数の存在チェック

```gdscript
if VariableManager.has_variable("count"):
    print("count変数が存在します")
```

---

## ベストプラクティス

### 1. 変数名の命名規則

```
良い例:
- event_001_completed
- alice_affection
- chapter_number
- met_character_bob

悪い例:
- e1
- a
- x
- flag1
```

### 2. システム変数の使い分け

```
セーブ変数:
- ゲーム内の状態
- キャラクター関係
- 進行フラグ

システム変数:
- プレイ回数
- 解放した実績
- 設定値
```

### 3. 初期値の設定

```
# 新規ゲーム開始時に初期化
@set chapter=1
@set player_name="主人公"
@set route=""
```

---

## トラブルシューティング

### Q1: 変数が設定されない

**原因**: 構文エラー

**確認点**:
```
正しい: @set count=10
間違い: @set count 10  (=が必要)
```

### Q2: 条件分岐が動作しない

**原因**: 条件式が不正

**確認点**:
```
正しい: @if count > 10
間違い: @if count>10  (スペースを入れる)
```

### Q3: @endif が見つからないエラー

**原因**: @if と @endif の対応が取れていない

**解決策**: すべての @if に対応する @endif があるか確認

---

## まとめ

変数管理システムにより:

✅ **フラグ管理** - ゲーム進行を管理
✅ **条件分岐** - 複雑なシナリオ分岐が可能
✅ **永続化** - セーブデータとシステム設定の分離
✅ **柔軟な式評価** - 比較、論理、算術演算

---

## 関連ファイル

- `scripts/variable_manager.gd` - 変数管理システム
- `scripts/commands/set_command.gd` - 変数設定コマンド
- `scripts/commands/if_command.gd` - 条件分岐コマンド
- `resources/scenarios/variable_test.txt` - テストシナリオ
