# BGM/SE停止コマンド仕様書

## 概要
BGMとSEを停止するコマンドを実装。
フェードアウト時間の指定、特定ファイルまたは全体の停止が可能。

---

## コマンド一覧

### @bgm
BGMを再生（旧 @music から改名）

**構文**:
```
@bgm ファイル名 [パラメータ...]
```

詳細は「musicコマンド拡張仕様書.md」を参照。

---

### @stopbgm
BGMを停止

**構文**:
```
@stopbgm [BGM名] [time:秒数]
```

**パラメータ**:
- **BGM名** (省略可): 停止するBGMのファイル名
  - 指定した場合、そのBGMが現在再生中なら停止
  - 省略した場合、現在再生中のBGMを停止
- **time:秒数** (省略可): フェードアウト時間（秒）
  - 省略した場合は即座に停止（0秒）

---

### @stopse
SEを停止

**構文**:
```
@stopse [SE名] [time:秒数]
```

**パラメータ**:
- **SE名** (省略可): 停止するSEのファイル名
  - 指定した場合、そのSEのみ停止
  - 省略した場合、再生中の全てのSEを停止
- **time:秒数** (省略可): フェードアウト時間（秒）
  - 省略した場合は即座に停止（0秒）

---

## 使用例

### 現在のBGMを即座に停止
```
@stopbgm
```

### 現在のBGMを2秒かけてフェードアウト
```
@stopbgm time:2.0
```

### 特定のBGMを停止（ファイル名指定）
```
@stopbgm peaceful_day
```

### 特定のBGMを3秒かけてフェードアウト
```
@stopbgm battle time:3.0
```

### 全てのSEを即座に停止
```
@stopse
```

### 特定のSEを1秒かけてフェードアウト
```
@stopse footsteps time:1.0
```

---

## シナリオ例

```
# BGMを再生
@bgm peaceful_day volume=80

主人公:静かな朝だ...

# BGMをフェードアウト
@stopbgm time:3.0

主人公:何か不穏な気配がする...

# 新しいBGMに切り替え
@bgm tension volume=90

# 戦闘シーン
@bgm battle loop=true

# 戦闘終了、BGM即座に停止
@stopbgm

# エンディング
@bgm ending loop=false

# エンディング後、ゆっくりフェードアウト
@stopbgm time:5.0
```

---

## 実装詳細

### scenario_manager.gd
`_parse_stop_command()` 関数:
- `@stopbgm` と `@stopse` をパース
- ファイル名と time: パラメータを抽出
- Dictionary形式で返却

### audio_manager.gd

#### BGM停止関数
- `stop_bgm(fade_duration)`: 現在のBGMを停止
- `stop_bgm_by_name(file_name, fade_duration)`: 特定のBGMを停止（現在再生中の場合のみ）

#### SE停止関数
- `stop_se_by_name(file_name, fade_duration)`: 特定のSEを停止
- `stop_all_se(fade_duration)`: 全てのSEを停止

#### フェード処理
- `fade_duration > 0.0` の場合、Tweenを使用してフェードアウト
- `fade_duration == 0.0` の場合、即座に停止

### game_manager.gd
- `_stop_bgm(params)`: stopbgmコマンドを処理
- `_stop_se(params)`: stopseコマンドを処理
- パラメータに応じて適切なAudioManager関数を呼び出し

---

## SE管理の拡張

従来のSE実装では個別ファイル名での管理ができなかったため、以下を変更:

### 変更前
```gdscript
var se_player: AudioStreamPlayer  # 単一プレイヤー
```

### 変更後
```gdscript
var se_players: Dictionary = {}  # SE名 -> AudioStreamPlayer
```

これにより:
- 複数のSEを同時再生可能
- 特定のSEのみを停止可能
- SE再生終了時に自動でプレイヤーを削除

---

## パラメータ仕様

### time: の書式
- `time:` の後に秒数を指定
- 小数点可能（例: `time:1.5`）
- 省略時は 0.0（即座に停止）

### パラメータの順序
以下の順序で指定可能:

**パターン1: ファイル名のみ**
```
@stopbgm peaceful_day
```

**パターン2: time のみ**
```
@stopbgm time:2.0
```

**パターン3: ファイル名 + time**
```
@stopbgm peaceful_day time:2.0
```

**パターン4: パラメータなし（全停止）**
```
@stopbgm
```

---

## 注意事項

### BGM名の一致判定
`stop_bgm_by_name()` は現在再生中のBGMとファイル名が一致する場合のみ停止します。

例:
```
@bgm peaceful_day
# ... 
@stopbgm battle  # peaceful_dayが再生中なので無視される
```

### SE停止のタイミング
SEは再生終了時に自動的にプレイヤーが削除されます。
長いSEを途中で停止したい場合は `@stopse` を使用してください。

---

## 今後の拡張

### クロスフェード
BGM切り替え時に古いBGMと新しいBGMを同時に再生:
```
@bgm new_track crossfade:2.0
```

### 音量変更
再生中のBGMの音量を徐々に変更:
```
@bgmvolume 50 time:3.0
```

### 一時停止/再開
```
@pausebgm
@resumebgm
```

---

## 実装日
2025年1月（初版）

## 変更履歴
- @music → @bgm に改名
- @stopbgm, @stopse コマンド追加
- SE管理方式を単一プレイヤーから複数プレイヤーに変更

## 関連ドキュメント
- musicコマンド拡張仕様書.md
- BGMシステム実装仕様書.md
- ADVデモ実装ログ.md
