# jarvis_intro.ps1 — Jarvis Voice + Iron Man Theme BG intro
# Plays JARVIS intro audio on Windows using winmm.dll

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class WinMM {
    [DllImport("winmm.dll", CharSet = CharSet.Unicode)]
    public static extern int mciSendString(string command, StringBuilder buffer, int bufferSize, IntPtr hwndCallback);
}
"@

$assetsDir = Join-Path $PSScriptRoot "assets"
$bgMusic = Join-Path $assetsDir "Iron Man Theme BG.mp3"
$jarvisVoice = Join-Path $assetsDir "JARVIS Voice.mp3"

if (-not (Test-Path $bgMusic)) {
    Write-Error "Missing: $bgMusic"
    exit 1
}
if (-not (Test-Path $jarvisVoice)) {
    Write-Error "Missing: $jarvisVoice"
    exit 1
}

# Play background music (Iron Man Theme)
$null = [WinMM]::mciSendString("open `"$bgMusic`" type MPEGVideo alias jard_bg", $null, 0, [IntPtr]::Zero)
$null = [WinMM]::mciSendString("set jard_bg time format milliseconds", $null, 0, [IntPtr]::Zero)
$null = [WinMM]::mciSendString("play jard_bg", $null, 0, [IntPtr]::Zero)

Start-Sleep -Milliseconds 500

# Play JARVIS voice
$null = [WinMM]::mciSendString("open `"$jarvisVoice`" type MPEGVideo alias jard_vc", $null, 0, [IntPtr]::Zero)
$null = [WinMM]::mciSendString("play jard_vc", $null, 0, [IntPtr]::Zero)

# Wait for JARVIS voice to finish
do {
    Start-Sleep -Milliseconds 300
    $status = New-Object System.Text.StringBuilder 128
    $null = [WinMM]::mciSendString("status jard_vc mode", $status, 128, [IntPtr]::Zero)
} while ($status.ToString() -eq "playing")

$null = [WinMM]::mciSendString("close jard_vc", $null, 0, [IntPtr]::Zero)

# Fade out BG music gently
$null = [WinMM]::mciSendString("stop jard_bg", $null, 0, [IntPtr]::Zero)
$null = [WinMM]::mciSendString("close jard_bg", $null, 0, [IntPtr]::Zero)
