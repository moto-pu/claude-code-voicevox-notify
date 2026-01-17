param(
    [string]$Title = "Claude Code",
    [string]$Message = "Task completed",
    [string]$Sound = "Default",
    [string]$AppLogo = "",
    [int]$Duration = 5
)

try {
    Import-Module BurntToast -ErrorAction Stop
    
    $ToastParams = @{
        Text = $Title, $Message
        Sound = $Sound
    }
    
    # アプリロゴがあれば追加
    if ($AppLogo -and (Test-Path $AppLogo)) {
        $ToastParams.AppLogo = $AppLogo
    }
    
    New-BurntToastNotification @ToastParams
    
} catch {
    # Fallback
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}
