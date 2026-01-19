# musicコマンド拡張仕様書

## 概要
シナリオファイルの@musicコマンドを拡張し、詳細なBGM制御を可能にする。

---

## 基本構文

```
@music ファイル名 [パラメータ...]
```

パラメータは `key=value` 形式で指定。スペース区切りで複数指定可能。

---

## パラメータ一覧

### volume
**説明**: BGMの音量を設定  
**範囲**: 0〜100  
**デフォルト**: 100  
**例**: `volume=80`

音量は内部的に dB に変換されます（0-100 → -80dB 〜 0dB）

---

### sprite_time
**説明**: 再生区間を指定  
**形式**: `開始ミリ秒-終了ミリ秒`  
**デフォルト**: ""（全体再生）  
**例**: `sprite_time=6000-10000`

6000-10000 と指定すると 00:06〜00:10 の4秒間を再生。  
loop=true の場合、この区間をループ再生。

**注意**: Godotの制約上、完全な実装には制限があります。loop_offsetのみ設定可能。

---

### loop
**説明**: ループ再生の有無  
**値**: true / false  
**デフォルト**: true  
**例**: `loop=false`

trueの場合、BGMを繰り返し再生。

---

### seek
**説明**: 再生開始位置  
**形式**: 秒数（小数点可）  
**デフォルト**: 0.0  
**例**: `seek=4.5`

4.5と指定すると、4.5秒進んだ位置からBGMが再生開始。

---

### restart
**説明**: 同じBGMが既に再生中の場合の処理  
**値**: true / false  
**デフォルト**: false  
**例**: `restart=true`

- **true**: 最初から再生し直す
- **false**: 無視（継続再生）

---

## 使用例

### 基本的な使用
```
@music peaceful_day
```
ファイル `peaceful_day.ogg` をデフォルト設定で再生。

---

### 音量を下げて再生
```
@music tension volume=60
```
通常より静かに再生。

---

### 途中から再生
```
@music opening seek=10.5
```
10.5秒の位置から再生開始。

---

### ループなし再生
```
@music ending loop=false
```
一度だけ再生して終了。

---

### 特定区間をループ
```
@music battle sprite_time=5000-15000 loop=true
```
00:05〜00:15の10秒間をループ再生。

---

### 複数パラメータの組み合わせ
```
@music boss_battle volume=80 seek=2.0 restart=true
```
音量80%、2秒から再生、同じBGMが流れていても再生し直す。

---

## シナリオ例

```
# タイトル画面
@music title volume=90

# 日常シーン
@bg classroom
@music peaceful_day

# 緊張シーン
@bg dark_room
@music tension volume=70 seek=5.0

# 戦闘シーン（ループ区間指定）
@bg battlefield
@music battle sprite_time=3000-20000 loop=true

# エンディング（ループなし）
@bg ending_scene
@music ending loop=false
```

---

## 実装詳細

### scenario_manager.gd
`_parse_music_command()` 関数で以下のパラメータをパース:
- key=value 形式を解析
- Dictionary形式で返却

### audio_manager.gd
`play_bgm_ex()` 関数で詳細制御:
- volume: 0-100 を dB に変換
- sprite_time: loop_offset に設定
- loop: AudioStream.loop プロパティに設定
- seek: AudioStreamPlayer.play(position) に渡す
- restart: 同じBGM判定と再生制御

### game_manager.gd
コマンドDictionaryをそのまま `AudioManager.play_bgm_ex()` に渡す。

---

## 注意事項

### sprite_time の制限
Godotでは再生終了時刻を直接指定できないため、`sprite_time` の終了時刻は完全には機能しません。  
ループオフセットのみ設定可能です。完全な実装にはタイマー処理が必要になります。

### 対応フォーマット
- AudioStreamOggVorbis (.ogg) - 推奨
- AudioStreamMP3 (.mp3)

### 後方互換性
パラメータなしで指定した場合、従来通りの動作になります。

---

## 今後の拡張

### クロスフェード
```
@music next_bgm crossfade=2.0
```
現在のBGMと次のBGMを2秒かけてクロスフェード。

### フェード時間指定
```
@music new_bgm fade=3.0
```
フェードイン時間を個別に指定。

### 完全な sprite_time 実装
タイマーで終了時刻を監視し、指定区間のみ再生。

---

## 実装日
2025年1月（初版）

## 関連ドキュメント
- BGMシステム実装仕様書.md
- ADVデモ実装ログ.md
