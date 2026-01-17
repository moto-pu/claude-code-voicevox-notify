# Claude Code VOICEVOX Notify

[English README](README.md)

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) の hooks 機能を使って、タスク完了時・入力待ち時に **VOICEVOX で音声通知** するスクリプト集です。

WSL2 + Windows 環境で動作し、作業中のブランチ名から課題番号を自動抽出して読み上げます。

## 特徴

- **VOICEVOX 音声合成** - 高品質な日本語音声で通知
- **Windows トースト通知** - 視覚的な通知も同時に表示
- **ブランチ名から課題番号を自動抽出** - Backlog/GitHub Issue 形式に対応 (例: `feature/PROJ-1234` → 「1234」を読み上げ)
- **読み上げ速度・抑揚のカスタマイズ** - 数字部分とメッセージ部分を別々に調整可能

## デモ

- タスク完了時: 「1234 が完了しました」
- 入力待ち時: 「1234 が入力待ちです」

## 必要な環境

- Windows 10/11 + WSL2
- [VOICEVOX](https://voicevox.hiroshiba.jp/) (ローカルで起動、デフォルトポート 50021)
- [BurntToast](https://github.com/Windos/BurntToast) PowerShell モジュール (トースト通知用)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI

## インストール

### 1. VOICEVOX のインストール

[VOICEVOX 公式サイト](https://voicevox.hiroshiba.jp/) からダウンロードしてインストール。
使用時は VOICEVOX を起動しておく必要があります。

### 2. BurntToast のインストール (PowerShell)

```powershell
Install-Module -Name BurntToast -Scope CurrentUser
```

### 3. スクリプトの配置

```bash
# Windows 側 (PowerShell スクリプト)
mkdir -p /mnt/c/Users/<USERNAME>/ClaudeScripts
cp windows/*.ps1 /mnt/c/Users/<USERNAME>/ClaudeScripts/

# WSL 側 (シェルスクリプト)
mkdir -p ~/.claude/scripts
cp wsl/notify-with-task.sh ~/.claude/scripts/
chmod +x ~/.claude/scripts/notify-with-task.sh
```

### 4. Claude Code hooks 設定

`~/.claude/settings.json` に以下を追加:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -File \"C:\\Users\\<USERNAME>\\ClaudeScripts\\toast-notify.ps1\" -Title \"Claude Code - Completed\" -Message \"タスクが完了しました\" -Sound \"Default\""
          },
          {
            "type": "command",
            "command": "~/.claude/scripts/notify-with-task.sh completed 2 3000"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -File \"C:\\Users\\<USERNAME>\\ClaudeScripts\\toast-notify.ps1\" -Title \"Claude Code - Input Required\" -Message \"入力待ちです\" -Sound \"SMS\""
          },
          {
            "type": "command",
            "command": "~/.claude/scripts/notify-with-task.sh waiting 2 3000"
          }
        ]
      }
    ]
  }
}
```

`<USERNAME>` は実際の Windows ユーザー名に置き換えてください。

## 使い方

### notify-with-task.sh

```bash
notify-with-task.sh <event_type> [speaker] [delay_ms] [speed_num] [speed_msg] [int_num] [int_msg]
```

| 引数 | 説明 | デフォルト |
|------|------|-----------|
| event_type | `completed` または `waiting` | 必須 |
| speaker | VOICEVOX スピーカー ID | 2 |
| delay_ms | 発話前の待機時間 (ミリ秒) | 3000 |
| speed_num | 数字部分の読み上げ速度 | 0.85 |
| speed_msg | メッセージ部分の読み上げ速度 | 1.0 |
| int_num | 数字部分の抑揚 | 1.2 |
| int_msg | メッセージ部分の抑揚 | 1.0 |

### voicevox-voice.ps1

```powershell
voicevox-voice.ps1 -Message "読み上げテキスト" [-Speaker 2] [-Speed 1.0] [-Intonation 1.0]
```

2つのメッセージを異なるパラメータで連続再生:

```powershell
voicevox-voice.ps1 -Message "1234" -Speed 0.85 -Message2 "が完了しました" -Speed2 1.0
```

### VOICEVOX スピーカー ID

| ID | キャラクター |
|----|-------------|
| 0 | 四国めたん (あまあま) |
| 1 | ずんだもん (あまあま) |
| 2 | 四国めたん (ノーマル) |
| 3 | ずんだもん (ノーマル) |
| ... | [VOICEVOX エディタで確認](https://voicevox.hiroshiba.jp/) |

## ファイル構成

```
claude-code-voicevox-notify/
├── README.md                  # 英語版ドキュメント
├── README.ja.md               # 日本語版ドキュメント
├── windows/
│   ├── voicevox-voice.ps1    # VOICEVOX API 呼び出し
│   └── toast-notify.ps1       # Windows トースト通知
├── wsl/
│   └── notify-with-task.sh    # ブランチ名から課題番号抽出 + 発話
└── examples/
    └── hooks-settings.json    # Claude Code hooks 設定例
```

## 動作の仕組み

```
[Claude Code hooks]
       │
       ▼
[notify-with-task.sh] ─── git branch から課題番号を抽出
       │                  例: feature/PROJ-1234 → 1234
       │                  数字をひらがなに変換 (1234 → いちにぃさんよん)
       ▼
[voicevox-voice.ps1] ─── VOICEVOX API (localhost:50021) に音声合成リクエスト
       │
       ▼
[Windows 音声再生]
```

## トラブルシューティング

### VOICEVOX に接続できない

- VOICEVOX が起動しているか確認
- デフォルトポート 50021 で起動しているか確認

```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:50021/speakers"
```

### トースト通知が表示されない

- BurntToast モジュールがインストールされているか確認

```powershell
Get-Module -ListAvailable BurntToast
```

### WSL から PowerShell が実行できない

- `powershell.exe` にパスが通っているか確認

```bash
which powershell.exe
```

## ライセンス

MIT License

## 関連リンク

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) - Anthropic 公式 CLI
- [Claude Code Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) - hooks 機能のドキュメント
- [VOICEVOX](https://voicevox.hiroshiba.jp/) - 無料の音声合成ソフトウェア
- [BurntToast](https://github.com/Windos/BurntToast) - PowerShell トースト通知モジュール
