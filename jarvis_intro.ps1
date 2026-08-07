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

# Re-encode to 128kbps via ffmpeg for consistent quality
$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if ($ffmpeg) {
    $bg128 = Join-Path $env:TEMP "jard_bg_128.mp3"
    $vc128 = Join-Path $env:TEMP "jard_vc_128.mp3"
    & ffmpeg -i $bgMusic -b:a 128k -ar 44100 -y $bg128 2>$null
    & ffmpeg -i $jarvisVoice -b:a 128k -ar 44100 -y $vc128 2>$null
    if ((Test-Path $bg128) -and (Test-Path $vc128)) {
        $bgMusic = $bg128
        $jarvisVoice = $vc128
    }
}

# Open both files
$null = [WinMM]::mciSendString("open `"$bgMusic`" type MPEGVideo alias jard_bg", $null, 0, [IntPtr]::Zero)
$null = [WinMM]::mciSendString("open `"$jarvisVoice`" type MPEGVideo alias jard_vc", $null, 0, [IntPtr]::Zero)

# Balance: JARVIS voice full volume, BG music at 25%
$null = [WinMM]::mciSendString("setaudio jard_vc volume to 400", $null, 0, [IntPtr]::Zero)
$null = [WinMM]::mciSendString("setaudio jard_bg volume to 120", $null, 0, [IntPtr]::Zero)

# Play both simultaneously
$null = [WinMM]::mciSendString("play jard_bg", $null, 0, [IntPtr]::Zero)
$null = [WinMM]::mciSendString("play jard_vc", $null, 0, [IntPtr]::Zero)

# Wait for JARVIS voice to finish (longer of the two)
do {
    Start-Sleep -Milliseconds 300
    $status = New-Object System.Text.StringBuilder 128
    $null = [WinMM]::mciSendString("status jard_vc mode", $status, 128, [IntPtr]::Zero)
} while ($status.ToString() -eq "playing")

# Fade out and close both
$null = [WinMM]::mciSendString("setaudio jard_bg volume to 50", $null, 0, [IntPtr]::Zero)
Start-Sleep -Milliseconds 500
$null = [WinMM]::mciSendString("close jard_vc", $null, 0, [IntPtr]::Zero)
$null = [WinMM]::mciSendString("close jard_bg", $null, 0, [IntPtr]::Zero)
