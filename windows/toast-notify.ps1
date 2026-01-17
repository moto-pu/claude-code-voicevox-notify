<#
.SYNOPSIS
    Windows Toast Notification Script
    Windows トースト通知スクリプト

.DESCRIPTION
    Shows a Windows toast notification using BurntToast module.
    Falls back to MessageBox if BurntToast is not available.
    BurntToast モジュールを使用して Windows トースト通知を表示します。
    BurntToast が利用できない場合は MessageBox にフォールバックします。

.PARAMETER Title
    Notification title / 通知のタイトル

.PARAMETER Message
    Notification message / 通知のメッセージ

.PARAMETER Sound
    Notification sound (Default, SMS, Mail, etc.) / 通知音 (Default, SMS, Mail 等)

.PARAMETER AppLogo
    Optional path to app logo image / アプリロゴ画像のパス (オプション)

.PARAMETER Duration
    Notification duration in seconds / 通知の表示時間 (秒)

.EXAMPLE
    .\toast-notify.ps1 -Title "Claude Code" -Message "Task completed" -Sound "Default"
    .\toast-notify.ps1 -Title "Claude Code" -Message "入力待ちです" -Sound "SMS"
#>

param(
    [string]$Title = "Claude Code",
    [string]$Message = "Task completed",
    [string]$Sound = "Default",
    [string]$AppLogo = "",
    [int]$Duration = 5
)

try {
    # Try to use BurntToast module / BurntToast モジュールを使用
    Import-Module BurntToast -ErrorAction Stop

    $ToastParams = @{
        Text = $Title, $Message
        Sound = $Sound
    }

    # Add app logo if specified and exists
    # アプリロゴが指定されていて存在すれば追加
    if ($AppLogo -and (Test-Path $AppLogo)) {
        $ToastParams.AppLogo = $AppLogo
    }

    New-BurntToastNotification @ToastParams

} catch {
    # Fallback to MessageBox if BurntToast fails
    # BurntToast が失敗した場合は MessageBox にフォールバック
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}
