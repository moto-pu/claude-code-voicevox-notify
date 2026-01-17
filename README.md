# Claude Code VOICEVOX Notify

[日本語版 README はこちら / Japanese README](README.ja.md)

Voice notification scripts for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) using **VOICEVOX** text-to-speech engine.

Get audio notifications when tasks complete or when Claude Code is waiting for your input.

## Features

- **VOICEVOX Voice Synthesis** - High-quality Japanese text-to-speech notifications
- **Windows Toast Notifications** - Visual notifications alongside audio
- **Auto-extract Issue Numbers** - Extracts issue numbers from git branch names (e.g., `feature/PROJ-1234` → reads "1234")
- **Customizable Speech** - Adjust speed and intonation separately for numbers and messages
- **Multi-language Support** - Japanese and English message support via `NOTIFY_LANG` environment variable

## Demo

**Japanese (default):**
- On task completion: "いちにぃさんよん が完了しました"
- On input waiting: "いちにぃさんよん が入力待ちです"

**English (`NOTIFY_LANG=en`):**
- On task completion: "one two three four has completed"
- On input waiting: "one two three four is waiting for input"

## Requirements

- Windows 10/11 + WSL2
- [VOICEVOX](https://voicevox.hiroshiba.jp/) (running locally on default port 50021)
- [BurntToast](https://github.com/Windos/BurntToast) PowerShell module (for toast notifications)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI

## Installation

### 1. Install VOICEVOX

Download and install from [VOICEVOX official site](https://voicevox.hiroshiba.jp/).
VOICEVOX must be running when using these scripts.

### 2. Install BurntToast (PowerShell)

```powershell
Install-Module -Name BurntToast -Scope CurrentUser
```

### 3. Deploy Scripts

```bash
# Windows side (PowerShell scripts)
mkdir -p /mnt/c/Users/<USERNAME>/ClaudeScripts
cp windows/*.ps1 /mnt/c/Users/<USERNAME>/ClaudeScripts/

# WSL side (Shell script)
mkdir -p ~/.claude/scripts
cp wsl/notify-with-task.sh ~/.claude/scripts/
chmod +x ~/.claude/scripts/notify-with-task.sh
```

### 4. Configure Claude Code Hooks

Add the following to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -File \"C:\\Users\\<USERNAME>\\ClaudeScripts\\toast-notify.ps1\" -Title \"Claude Code - Completed\" -Message \"Task completed\" -Sound \"Default\""
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
            "command": "powershell.exe -File \"C:\\Users\\<USERNAME>\\ClaudeScripts\\toast-notify.ps1\" -Title \"Claude Code - Input Required\" -Message \"Waiting for input\" -Sound \"SMS\""
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

Replace `<USERNAME>` with your actual Windows username.

## Usage

### notify-with-task.sh

```bash
notify-with-task.sh <event_type> [speaker] [delay_ms] [speed_num] [speed_msg] [int_num] [int_msg]
```

| Argument | Description | Default |
|----------|-------------|---------|
| event_type | `completed` or `waiting` | Required |
| speaker | VOICEVOX speaker ID | 2 |
| delay_ms | Delay before speech (milliseconds) | 3000 |
| speed_num | Speech speed for number part | 0.85 |
| speed_msg | Speech speed for message part | 1.0 |
| int_num | Intonation for number part | 1.2 |
| int_msg | Intonation for message part | 1.0 |

**Environment Variables:**

| Variable | Description | Default |
|----------|-------------|---------|
| NOTIFY_LANG | Message language: `ja` (Japanese) or `en` (English) | `ja` |

**Example with English messages:**

```bash
NOTIFY_LANG=en ~/.claude/scripts/notify-with-task.sh completed 2 3000
```

**Claude Code hooks example (English):**

```json
{
  "type": "command",
  "command": "NOTIFY_LANG=en ~/.claude/scripts/notify-with-task.sh completed 2 3000"
}
```

### voicevox-voice.ps1

```powershell
voicevox-voice.ps1 -Message "Text to speak" [-Speaker 2] [-Speed 1.0] [-Intonation 1.0]
```

Two messages with different parameters:

```powershell
voicevox-voice.ps1 -Message "1234" -Speed 0.85 -Message2 "completed" -Speed2 1.0
```

### VOICEVOX Speaker IDs

| ID | Character |
|----|-----------|
| 0 | Shikoku Metan (Sweet) |
| 1 | Zundamon (Sweet) |
| 2 | Shikoku Metan (Normal) |
| 3 | Zundamon (Normal) |
| ... | [See VOICEVOX Editor](https://voicevox.hiroshiba.jp/) |

## File Structure

```
claude-code-voicevox-notify/
├── README.md                  # English documentation
├── README.ja.md               # Japanese documentation
├── windows/
│   ├── voicevox-voice.ps1    # VOICEVOX API caller
│   └── toast-notify.ps1       # Windows toast notification
├── wsl/
│   └── notify-with-task.sh    # Extract issue number from branch + speak
└── examples/
    └── hooks-settings.json    # Claude Code hooks configuration example
```

## How It Works

```
[Claude Code hooks]
       │
       ▼
[notify-with-task.sh] ─── Extract issue number from git branch
       │                  e.g., feature/PROJ-1234 → 1234
       │                  Convert digits to hiragana for natural speech
       ▼
[voicevox-voice.ps1] ─── Send synthesis request to VOICEVOX API (localhost:50021)
       │
       ▼
[Windows audio playback]
```

## Troubleshooting

### Cannot connect to VOICEVOX

- Verify VOICEVOX is running
- Check it's running on default port 50021

```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:50021/speakers"
```

### Toast notifications not showing

- Verify BurntToast module is installed

```powershell
Get-Module -ListAvailable BurntToast
```

### Cannot execute PowerShell from WSL

- Verify `powershell.exe` is in PATH

```bash
which powershell.exe
```

## Credits & Acknowledgments

### VOICEVOX

This project uses [VOICEVOX](https://voicevox.hiroshiba.jp/), a free Japanese text-to-speech software.

> Audio generated by this tool is powered by **VOICEVOX**.
> Please refer to [VOICEVOX Terms of Use](https://voicevox.hiroshiba.jp/term/) for character-specific licensing.

When using the generated audio, please credit "VOICEVOX: [Character Name]" as required by the VOICEVOX license.

### Inspiration

This project was inspired by [usabarashi/voicevox-cli](https://github.com/usabarashi/voicevox-cli) - a sophisticated VOICEVOX CLI tool for Apple Silicon Macs. Special thanks to [@usabarashi](https://github.com/usabarashi) for the excellent work that motivated this project.

## License

MIT License

## Related Links

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) - Anthropic's official CLI
- [Claude Code Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) - Hooks documentation
- [VOICEVOX](https://voicevox.hiroshiba.jp/) - Free text-to-speech software
- [BurntToast](https://github.com/Windos/BurntToast) - PowerShell toast notification module
