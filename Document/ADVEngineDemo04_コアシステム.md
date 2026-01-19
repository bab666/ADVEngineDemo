## コアシステム

### GameManager

**役割**: ゲーム進行の中核制御

**主要メソッド**:

- `_ready()`: 初期化、シグナル接続、シナリオ読み込み
- `_on_scenario_line_changed(command: Dictionary)`: コマンド実行
- `_on_advance_requested()`: 次行へ進む
- `start_wait(duration: float)`: 待機開始
- `cancel_wait()`: 待機キャンセル

**コンテキスト構築**:

```gdscript
command_context = {
    "message_window": MessageWindow,
    "background": TextureRect,
    "character_display": CharacterDisplay,
    "scenario_manager": ScenarioManager,
    "game_manager": GameManager,
    "window_manager": WindowManager
}
```

### ScenarioManager

**役割**: シナリオファイルのパース・進行管理

**ファイル形式**: UTF-8テキスト (`.txt`)

**主要メソッド**:

- `load_scenario(file_path: String) -> bool`: シナリオ読み込み
- `next_line() -> Dictionary`: 次の行を取得・実行
- `has_next() -> bool`: 次の行が存在するか確認
- `_parse_line(line: String) -> Dictionary`: 行をパース
- `_parse_command(line: String) -> Dictionary`: コマンド行をパース
- `_parse_dialogue(line: String) -> Dictionary`: 台詞行をパース

**シグナル**:

- `scenario_line_changed(command: Dictionary)`: 行変更時
- `scenario_finished`: シナリオ終了時

### CommandRegistry

**役割**: コマンドの登録・管理・実行

**主要メソッド**:

- `register_builtin_commands()`: 組み込みコマンド登録
- `register_command(command: BaseCommand)`: コマンド登録
- `get_command(cmd_name: String) -> BaseCommand`: コマンド取得
- `execute_command(cmd_name, params, context) -> bool`: コマンド実行

**登録されるコマンド**:

```gdscript
func register_builtin_commands():
    register_command(BgCommand.new())
    register_command(CharaCommand.new())
    register_command(CharaHideCommand.new())
    register_command(DialogueCommand.new())
    register_command(WindowCommand.new())
    register_command(WaitCommand.new())
    register_command(WaitCancelCommand.new())
    register_command(BgmCommand.new())
    register_command(StopBgmCommand.new())
    register_command(StopSeCommand.new())
```

---

## コマンドシステム

### BaseCommand（基底クラス）

全てのコマンドが継承する抽象クラス。

**必須メソッド**:

```gdscript
func get_command_name() -> String:
    # コマンド名を返す（例: "bg", "chara"）
    pass

func get_description() -> String:
    # コマンドの説明文
    pass

func execute(params: Dictionary, context: Dictionary) -> void:
    # コマンドの実際の処理
    pass

func requires_wait() -> bool:
    # ユーザー入力待ちが必要か（デフォルト: false）
    return false
```

