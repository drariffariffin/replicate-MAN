# TTS Server — Osman Voice (Port 5050)
# Equivalent kepada TTS server di MacBook Dr. Ariff
# POST http://localhost:5050/  Body: {"text": "teks nak sebut", "voice": "Reza"}
# Voice "Reza" mapped to ms-MY-OsmanNeural, default rate -10%

param(
    [int]$Port = 5050
)

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

function Play-Audio {
    param([string]$mp3Path)
    $null = [WinMM]::mciSendString("open `"$mp3Path`" type MPEGVideo alias orca_tts_srv", $null, 0, [IntPtr]::Zero)
    $null = [WinMM]::mciSendString("play orca_tts_srv", $null, 0, [IntPtr]::Zero)
    do {
        Start-Sleep -Milliseconds 300
        $status = New-Object System.Text.StringBuilder 128
        $null = [WinMM]::mciSendString("status orca_tts_srv mode", $status, 128, [IntPtr]::Zero)
    } while ($status.ToString() -eq "playing")
    $null = [WinMM]::mciSendString("close orca_tts_srv", $null, 0, [IntPtr]::Zero)
}

function Generate-TTS {
    param([string]$text, [string]$voice, [int]$rate)
    if (-not $voice) { $voice = "ms-MY-OsmanNeural" }
    if (-not $rate) { $rate = -10 }

    $tmpFile = Join-Path $env:TEMP "orca_tts_srv_$([System.Guid]::NewGuid().ToString().Substring(0,8)).mp3"

    & edge-tts --voice $voice --rate "$rate%" --text $text --write-media $tmpFile 2>$null

    if (Test-Path $tmpFile) {
        # Re-encode ke 128kbps guna ffmpeg (kalau ada)
        $ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
        if ($ffmpeg) {
            $tmp128 = Join-Path $env:TEMP "orca_tts_srv_128_$([System.Guid]::NewGuid().ToString().Substring(0,8)).mp3"
            & ffmpeg -i $tmpFile -b:a 128k -ar 44100 -y $tmp128 2>$null
            if (Test-Path $tmp128) {
                Remove-Item $tmpFile -Force
                Move-Item $tmp128 $tmpFile -Force
            }
        }
        Play-Audio $tmpFile
        Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
    }
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()

Write-Output "TTS Server running on http://localhost:$Port/"
Write-Output "Voice: ms-MY-OsmanNeural (Osman), Rate: -10%"
Write-Output "POST {\"text\":\"teks\", \"voice\":\"Osman\"}"

while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $resp = $ctx.Response

    if ($req.HttpMethod -eq "POST") {
        $reader = New-Object System.IO.StreamReader($req.InputStream)
        $body = $reader.ReadToEnd()
        $reader.Close()

        try {
            $json = $body | ConvertFrom-Json
            $text = $json.text
            $voiceReq = $json.voice

            $voice = "ms-MY-OsmanNeural"
            if ($voiceReq) {
                switch -Wildcard ($voiceReq.ToLower()) {
                    "reza" { $voice = "ms-MY-OsmanNeural" }
                    "osman" { $voice = "ms-MY-OsmanNeural" }
                    "yasmin" { $voice = "ms-MY-YasminNeural" }
                    "ardi" { $voice = "id-ID-ArdiNeural" }
                    "gadis" { $voice = "id-ID-GadisNeural" }
                }
            }

            if ($text) {
                Generate-TTS -text $text -voice $voice -rate -10

                $resp.StatusCode = 200
                $resp.ContentType = "application/json"
                $msg = [System.Text.Encoding]::UTF8.GetBytes('{"status":"ok","voice":"' + $voice + '"}')
                $resp.OutputStream.Write($msg, 0, $msg.Length)
            } else {
                $resp.StatusCode = 400
                $msg = [System.Text.Encoding]::UTF8.GetBytes('{"error":"missing text field"}')
                $resp.OutputStream.Write($msg, 0, $msg.Length)
            }
        } catch {
            $resp.StatusCode = 500
            $msg = [System.Text.Encoding]::UTF8.GetBytes('{"error":"' + $_.Exception.Message + '"}')
            $resp.OutputStream.Write($msg, 0, $msg.Length)
        }
    } else {
        $resp.StatusCode = 200
        $resp.ContentType = "text/html"
        $html = @"
<html><body style='font-family:sans-serif;padding:2rem'>
<h1>Orca TTS Server</h1>
<p>POST / {"text":"teks", "voice":"Osman"}</p>
<p>Voices: Osman (ms-MY), Yasmin (ms-MY), Ardi (id-ID), Gadis (id-ID)</p>
</body></html>
"@
        $msg = [System.Text.Encoding]::UTF8.GetBytes($html)
        $resp.OutputStream.Write($msg, 0, $msg.Length)
    }

    $resp.Close()
}

$listener.Stop()
