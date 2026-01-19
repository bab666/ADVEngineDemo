### 実装済みコマンド一覧

#### @bg - 背景切り替え

```
@bg room
```

- **パラメータ**: `image` (画像名)
- **処理**: `res://resources/backgrounds/{image}.png` を読み込んで背景に設定
- **待機**: なし

#### @chara - キャラクター表示

```
@chara alice normal 1920 540
```

- `パラメータ: 

- `pos:auto` (自動中央) / `pos:x,y` (座標指定)

  `scale=1.0` (拡大縮小)

  `time=1000` (フェード時間ms)

  `wait=true` (演出完了待ち)

  `reflect=true` (左右反転)

  `layer=1` (表示レイヤー順)

  `src=[DataID]` (データ元ID指定。分身用)

  

- **処理**: キャラクター立ち絵を指定位置に表示

- **待機**: なし

#### @chara_hide - キャラクター非表示

```
@chara_hide alice
```

- **パラメータ**: `id`
- **処理**: 指定キャラクターを非表示
- **待機**: なし

#### (dialogue) - 台詞表示

```
主人公:おはよう。
```

- **パラメータ**: `character`, `text`
- **処理**: メッセージウインドウに台詞を表示
- **待機**: あり（ユーザークリック待ち）

#### @bgm - BGM再生

```
@bgm file=peaceful_day volume=80 loop=true
```

- **パラメータ**: 
  - `file`: ファイル名（必須）
  - `volume`: 音量 0-100 (デフォルト: 100)
  - `loop`: ループ true/false (デフォルト: true)
  - `seek`: 再生位置（秒）
  - `restart`: 同じBGMを最初から再生 true/false
  - `sprite_time`: フェード時間（秒）
- **処理**: BGMを再生、フェードイン
- **待機**: なし

#### @stopbgm - BGM停止

```
@stopbgm time=2.0
```

- **パラメータ**: 
  - `file`: 特定ファイルを停止（省略時は全BGM）
  - `time`: フェードアウト時間（秒）
- **処理**: BGMをフェードアウトして停止
- **待機**: なし

#### @stopse - SE停止

```
@stopse time=1.0
```

- **パラメータ**: 
  - `file`: 特定ファイルを停止（省略時は全SE）
  - `time`: フェードアウト時間（秒）
- **処理**: SEをフェードアウトして停止
- **待機**: なし

#### @wait - 時間待機

```
@wait time=2000
```

- **パラメータ**: `time` (ミリ秒)
- **処理**: 指定時間待機（自動進行を一時停止）
- **待機**: あり（時間経過で自動解除）

#### @wait_cancel - 待機キャンセル

```
@wait_cancel
```

- **パラメータ**: なし
- **処理**: 現在の待機状態をキャンセル
- **待機**: なし

#### @window - ウインドウ切り替え

```
@window default
@window sub
```

- **パラメータ**: `window_id` (ウインドウID)
- **処理**: 表示するメッセージウインドウを切り替え
- **待機**: なし



### 新規コマンドの追加方法

#### 1. コマンドクラス作成

`scripts/commands/my_command.gd`:

```gdscript
extends BaseCommand
class_name MyCommand

func get_command_name() -> String:
    return "mycommand"

func get_description() -> String:
    return "私のカスタムコマンド"

func execute(params: Dictionary, context: Dictionary) -> void:
    print("実行！", params)

func requires_wait() -> bool:
    return false
```

#### 2. CommandRegistryに登録

`scripts/command_registry.gd` の `register_builtin_commands()`:

```gdscript
func register_builtin_commands():
    # ... 既存のコマンド
    register_command(MyCommand.new())  # 追加
```

#### 3. シナリオで使用

```
@mycommand param1 param2
```

これだけで完了！`game_manager.gd` の変更は不要。