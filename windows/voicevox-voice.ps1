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

# 待ち時間が指定されていれば待機
if ($DelayMilliseconds -gt 0) {
    Start-Sleep -Milliseconds $DelayMilliseconds
}

function Speak-Text {
    param([string]$Text, [int]$Spk, [double]$Spd, [double]$Int)
    
    Add-Type -AssemblyName System.Web
    $url = "http://127.0.0.1:50021"
    $enc = [System.Web.HttpUtility]::UrlEncode($Text, [System.Text.Encoding]::UTF8)
    $q = Invoke-RestMethod -Uri "$url/audio_query?text=$enc&speaker=$Spk" -Method Post
    $q.speedScale = $Spd
    $q.intonationScale = $Int
    $audio = Invoke-WebRequest -Uri "$url/synthesis?speaker=$Spk" -Method Post -Body ($q | ConvertTo-Json -Depth 10) -ContentType "application/json" -UseBasicParsing
    $tmp = "$env:TEMP\vv_$(Get-Random).wav"
    [IO.File]::WriteAllBytes($tmp, $audio.Content)
    $p = New-Object Media.SoundPlayer($tmp)
    $p.PlaySync()
    $p.Dispose()
    Remove-Item $tmp -Force -EA 0
}

try {
    Speak-Text -Text $Message -Spk $Speaker -Spd $Speed -Int $Intonation
    if ($Message2 -ne "") {
        Speak-Text -Text $Message2 -Spk $Speaker -Spd $Speed2 -Int $Intonation2
    }
} catch {
    Write-Error "VOICEVOX Error: $_"
    exit 1
}
