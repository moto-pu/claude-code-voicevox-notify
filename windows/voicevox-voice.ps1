<#
.SYNOPSIS
    VOICEVOX Text-to-Speech Script
    VOICEVOX 音声合成スクリプト

.DESCRIPTION
    Sends text to VOICEVOX API for speech synthesis and plays the audio.
    VOICEVOX API にテキストを送信して音声合成し、再生します。

.PARAMETER Message
    Text to speak / 読み上げるテキスト

.PARAMETER Speaker
    VOICEVOX speaker ID (default: 1) / VOICEVOX スピーカー ID (デフォルト: 1)

.PARAMETER DelayMilliseconds
    Delay before speaking in milliseconds / 発話前の待機時間 (ミリ秒)

.PARAMETER Speed
    Speech speed (default: 1.0) / 読み上げ速度 (デフォルト: 1.0)

.PARAMETER Intonation
    Speech intonation (default: 1.0) / 抑揚 (デフォルト: 1.0)

.PARAMETER Message2
    Optional second message with separate parameters
    別パラメータで再生する2つ目のメッセージ (オプション)

.PARAMETER Speed2
    Speed for second message / 2つ目のメッセージの速度

.PARAMETER Intonation2
    Intonation for second message / 2つ目のメッセージの抑揚

.EXAMPLE
    .\voicevox-voice.ps1 -Message "Hello" -Speaker 2
    .\voicevox-voice.ps1 -Message "1234" -Speed 0.85 -Message2 "completed" -Speed2 1.0
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Message,
    [int]$Speaker = 1,
    [int]$DelayMilliseconds = 0,
    [double]$Speed = 1.0,
    [double]$Intonation = 1.0,
    [string]$Message2 = "",
    [double]$Speed2 = 1.0,
    [double]$Intonation2 = 1.0
)

# Wait if delay is specified
# 待機時間が指定されていれば待機
if ($DelayMilliseconds -gt 0) {
    Start-Sleep -Milliseconds $DelayMilliseconds
}

# Function to synthesize and play speech
# 音声合成・再生関数
function Speak-Text {
    param([string]$Text, [int]$Spk, [double]$Spd, [double]$Int)

    Add-Type -AssemblyName System.Web
    $url = "http://127.0.0.1:50021"

    # URL encode the text / テキストをURLエンコード
    $enc = [System.Web.HttpUtility]::UrlEncode($Text, [System.Text.Encoding]::UTF8)

    # Get audio query from VOICEVOX / VOICEVOX から音声クエリを取得
    $q = Invoke-RestMethod -Uri "$url/audio_query?text=$enc&speaker=$Spk" -Method Post

    # Set speed and intonation / 速度と抑揚を設定
    $q.speedScale = $Spd
    $q.intonationScale = $Int

    # Synthesize audio / 音声合成
    $audio = Invoke-WebRequest -Uri "$url/synthesis?speaker=$Spk" -Method Post -Body ($q | ConvertTo-Json -Depth 10) -ContentType "application/json" -UseBasicParsing

    # Save to temp file and play / 一時ファイルに保存して再生
    $tmp = "$env:TEMP\vv_$(Get-Random).wav"
    [IO.File]::WriteAllBytes($tmp, $audio.Content)
    $p = New-Object Media.SoundPlayer($tmp)
    $p.PlaySync()
    $p.Dispose()

    # Clean up temp file / 一時ファイルを削除
    Remove-Item $tmp -Force -EA 0
}

try {
    # Speak first message / 1つ目のメッセージを再生
    Speak-Text -Text $Message -Spk $Speaker -Spd $Speed -Int $Intonation

    # Speak second message if provided / 2つ目のメッセージがあれば再生
    if ($Message2 -ne "") {
        Speak-Text -Text $Message2 -Spk $Speaker -Spd $Speed2 -Int $Intonation2
    }
} catch {
    Write-Error "VOICEVOX Error: $_"
    exit 1
}
