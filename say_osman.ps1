# say_osman.ps1 — Windows TTS dengan suara Osman (ms-MY-OsmanNeural)
# Equivalent kepada ~/say_osman.sh di MacBook Dr. Ariff
# Usage: say_osman.ps1 "teks nak sebut"
#        echo "teks nak sebut" | say_osman.ps1

param(
    [string]$text = ""
)

# Kalau ada pipe input, guna tu. Kalau ada arg, guna arg.
if ([string]::IsNullOrEmpty($text)) {
    $text = $input | Out-String
}
if ([string]::IsNullOrWhiteSpace($text)) {
    Write-Error "Usage: say_osman.ps1 [text]  atau  echo 'text' | say_osman.ps1"
    exit 1
}

$text = $text.Trim()

# Refresh PATH supaya edge-tts dapat dicari
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

$tmpFile = Join-Path $env:TEMP "orca_tts_$([System.Guid]::NewGuid().ToString().Substring(0,8)).mp3"

try {
    # Generate audio dengan edge-tts (Osman, rate -10%)
    & edge-tts --voice "ms-MY-OsmanNeural" --rate="-10%" --text $text --write-media $tmpFile 2>$null

    if (-not (Test-Path $tmpFile)) {
        Write-Error "edge-tts gagal menghasilkan audio"
        exit 1
    }

    # Re-encode ke 128kbps guna ffmpeg (kalau ada)
    $ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if ($ffmpeg) {
        $tmp128 = Join-Path $env:TEMP "orca_tts_128_$([System.Guid]::NewGuid().ToString().Substring(0,8)).mp3"
        & ffmpeg -i $tmpFile -b:a 128k -ar 44100 -y $tmp128 2>$null
        if (Test-Path $tmp128) {
            Remove-Item $tmpFile -Force
            Move-Item $tmp128 $tmpFile -Force
        }
    }

    # Mainkan audio guna Windows MCI (Media Control Interface) — tanpa UI, macam afplay
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class WinMM {
    [DllImport("winmm.dll", CharSet = CharSet.Unicode)]
    public static extern int mciSendString(string command, StringBuilder buffer, int bufferSize, IntPtr hwndCallback);
}
"@

    $null = [WinMM]::mciSendString("open `"$tmpFile`" type MPEGVideo alias orca_tts", $null, 0, [IntPtr]::Zero)

    # Tunggu audio habis main — check status setiap 500ms
    $null = [WinMM]::mciSendString("play orca_tts", $null, 0, [IntPtr]::Zero)

    do {
        Start-Sleep -Milliseconds 500
        $status = New-Object System.Text.StringBuilder 128
        $null = [WinMM]::mciSendString("status orca_tts mode", $status, 128, [IntPtr]::Zero)
    } while ($status.ToString() -eq "playing")

    $null = [WinMM]::mciSendString("close orca_tts", $null, 0, [IntPtr]::Zero)

} finally {
    if (Test-Path $tmpFile) {
        Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
    }
}
