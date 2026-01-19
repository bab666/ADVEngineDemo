## アーキテクチャ

### 設計思想

#### 1. コマンドパターン

各機能を独立したコマンドクラスとして実装し、動的に登録・実行可能にする。

- **利点**: 拡張性、保守性、テスタビリティの向上
- **実装**: `BaseCommand` を継承したコマンドクラス

#### 2. マネージャーパターン

機能ごとにマネージャークラスを配置し、責任を分離。

- `GameManager`: 全体の制御
- `ScenarioManager`: シナリオ管理
- `WindowManager`: ウインドウ管理
- `AudioManager`: オーディオ管理（AutoLoad）
- `CommandRegistry`: コマンド管理

#### 3. データ駆動設計

設定やデータを外部ファイル（JSON）で管理し、コードの変更なしに調整可能にする。

- キャラクターデータ: `characters_data/*.json`
- ウインドウ設定: `system/windows_config.json`

### データフロー

```
シナリオファイル (.txt)
    ↓
ScenarioManager (パース)
    ↓
GameManager (コンテキスト構築)
    ↓
CommandRegistry (コマンド実行)
    ↓
各コマンドクラス (実際の処理)
    ↓
UI/表示システム
```

---

