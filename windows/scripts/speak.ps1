# speak.ps1 - Baca teks kuat dalam bahasa Melayu.
# Rantaian tiga lapis (jatuh ke bawah bila satu gagal):
#   1. ElevenLabs  - suara custom (cth Nora). Perlu kunci API. Hanya jalan bila voiceId diisi.
#   2. edge-tts    - ms-MY-OsmanNeural / ms-MY-YasminNeural (perlu internet).
#   3. WinRT       - suara OneCore ms-MY (luar talian; TIADA di PC ini, jadi ini jarang menolong).
# Guna: powershell -File speak.ps1 -Text "Helo dunia"
#       powershell -File speak.ps1 -FromFile C:\path\teks.txt
param(
    [Parameter(ValueFromPipeline = $true)]
    [string]$Text,
    [string]$FromFile,
    [string]$Voice,
    [string]$FallbackVoice = 'Microsoft Rizwan',
    [string]$Loudness = '+40%',
    [string]$Rate = '-10%',
    [switch]$NoElevenLabs
)

$ErrorActionPreference = 'Stop'

$log = Join-Path $PSScriptRoot 'speak.log'
function Log($m) { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  [speak] $m" | Add-Content -LiteralPath $log -Encoding UTF8 }

# ---------- Konfigurasi ----------
$cfgPath = Join-Path $PSScriptRoot 'voice-config.json'
$cfg = $null
if (Test-Path $cfgPath) {
    try { $cfg = Get-Content -LiteralPath $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { Log "voice-config.json rosak: $($_.Exception.Message)" }
}
if (-not $Voice) {
    if ($cfg -and $cfg.edgeVoice) { $Voice = $cfg.edgeVoice } else { $Voice = 'ms-MY-OsmanNeural' }
}

# Kunci ElevenLabs: env var dahulu, kemudian fail DPAPI (disulit untuk pengguna ini sahaja).
function Get-ElevenLabsKey {
    if ($env:ELEVENLABS_API_KEY) { return $env:ELEVENLABS_API_KEY }
    $keyFile = Join-Path $PSScriptRoot '.elevenlabs-key'
    if (-not (Test-Path $keyFile)) { return $null }
    try {
        $sec = Get-Content -LiteralPath $keyFile -Raw | ConvertTo-SecureString
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
        try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
        finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    } catch { Log "kunci EL tak dapat dibaca: $($_.Exception.Message)"; return $null }
}

function Get-CleanText($t) {
    $t = [regex]::Replace($t, '(?s)```.*?```', ' ')            # blok kod
    $t = [regex]::Replace($t, '`[^`]*`', ' ')                  # kod inline
    $t = [regex]::Replace($t, '!?\[([^\]]*)\]\([^)]*\)', '$1')  # pautan/imej
    $t = [regex]::Replace($t, '[*_#>|]', ' ')                  # penanda markdown
    $t = [regex]::Replace($t, '[\uD800-\uDFFF]', ' ')          # emoji (surrogate pair)
    $t = [regex]::Replace($t, '\s+', ' ').Trim()
    return $t
}

# Main audio MP3 guna Windows MCI (winmm) - tanpa UI, tanpa apartment STA.
function Play-Media($path) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class WinMM {
    [DllImport("winmm.dll", CharSet = CharSet.Unicode)]
    public static extern int mciSendString(string command, StringBuilder buffer, int bufferSize, IntPtr hwndCallback);
}
"@ -ErrorAction SilentlyContinue

    $alias = "claude_tts_$PID"
    $null = [WinMM]::mciSendString("open `"$path`" type MPEGVideo alias $alias", $null, 0, [IntPtr]::Zero)
    try {
        $null = [WinMM]::mciSendString("play $alias", $null, 0, [IntPtr]::Zero)
        do {
            Start-Sleep -Milliseconds 300
            $status = New-Object System.Text.StringBuilder 128
            $null = [WinMM]::mciSendString("status $alias mode", $status, 128, [IntPtr]::Zero)
        } while ($status.ToString() -eq 'playing')
    } finally {
        $null = [WinMM]::mciSendString("close $alias", $null, 0, [IntPtr]::Zero)
    }
}

function Invoke-ElevenLabs($t) {
    if ($NoElevenLabs) { throw 'ElevenLabs dilangkau (-NoElevenLabs)' }
    if (-not $cfg -or $cfg.provider -eq 'edge') { throw 'provider=edge, ElevenLabs dimatikan' }
    $voiceId = $null
    if ($cfg.elevenLabs) { $voiceId = $cfg.elevenLabs.voiceId }
    if (-not $voiceId) { throw 'voiceId ElevenLabs belum diisi' }
    $key = Get-ElevenLabsKey
    if (-not $key) { throw 'kunci ElevenLabs tiada' }

    $modelId = 'eleven_multilingual_v2'
    if ($cfg.elevenLabs.modelId) { $modelId = $cfg.elevenLabs.modelId }
    $stability = 0.5; if ($null -ne $cfg.elevenLabs.stability) { $stability = $cfg.elevenLabs.stability }
    $simBoost = 0.75; if ($null -ne $cfg.elevenLabs.similarityBoost) { $simBoost = $cfg.elevenLabs.similarityBoost }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $outFile = Join-Path $env:TEMP ("claude-el-{0}.mp3" -f $PID)
    $body = @{
        text           = $t
        model_id       = $modelId
        voice_settings = @{ stability = $stability; similarity_boost = $simBoost }
    } | ConvertTo-Json -Depth 5

    try {
        Invoke-RestMethod -Method Post `
            -Uri "https://api.elevenlabs.io/v1/text-to-speech/$voiceId" `
            -Headers @{ 'xi-api-key' = $key; 'Accept' = 'audio/mpeg' } `
            -ContentType 'application/json; charset=utf-8' `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
            -OutFile $outFile
        if (-not (Test-Path $outFile) -or (Get-Item $outFile).Length -lt 1024) { throw 'ElevenLabs hasilkan audio kosong' }
        Log ("elevenlabs/$voiceId $((Get-Item $outFile).Length) bait")
        Play-Media $outFile
    } finally {
        Remove-Item $outFile -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-EdgeTts($t) {
    $py = (Get-Command python -ErrorAction SilentlyContinue).Source
    if (-not $py) { throw 'python tak dijumpai' }
    $inFile  = Join-Path $env:TEMP ("claude-tts-{0}.txt" -f $PID)
    $outFile = Join-Path $env:TEMP ("claude-tts-{0}.mp3" -f $PID)
    # edge-tts baca fail sebagai UTF-8; tulis tanpa BOM supaya aksara pertama tak rosak
    [System.IO.File]::WriteAllText($inFile, $t, (New-Object System.Text.UTF8Encoding($false)))
    try {
        # Guna bentuk --rate=... kerana nilai negatif (-10%) akan disalah anggap sebagai flag
        & $py -m edge_tts --voice $Voice "--volume=$Loudness" "--rate=$Rate" --file $inFile --write-media $outFile | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "edge-tts keluar dengan kod $LASTEXITCODE" }
        if (-not (Test-Path $outFile) -or (Get-Item $outFile).Length -lt 1024) { throw 'edge-tts hasilkan audio kosong' }
        Log ("$Voice $((Get-Item $outFile).Length) bait")
        Play-Media $outFile
    } finally {
        Remove-Item $inFile, $outFile -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-WinRtTts($t) {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    [Windows.Media.SpeechSynthesis.SpeechSynthesizer, Windows.Media, ContentType = WindowsRuntime] | Out-Null
    [Windows.Storage.Streams.DataReader, Windows.Storage.Streams, ContentType = WindowsRuntime] | Out-Null

    $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
    })[0]

    function Await($op, $type) {
        $task = $asTaskGeneric.MakeGenericMethod($type).Invoke($null, @($op))
        $task.Wait(-1) | Out-Null
        $task.Result
    }

    $synth = New-Object Windows.Media.SpeechSynthesis.SpeechSynthesizer
    $picked = [Windows.Media.SpeechSynthesis.SpeechSynthesizer]::AllVoices |
        Where-Object { $_.DisplayName -eq $FallbackVoice } | Select-Object -First 1
    if (-not $picked) {
        $picked = [Windows.Media.SpeechSynthesis.SpeechSynthesizer]::AllVoices |
            Where-Object { $_.Language -eq 'ms-MY' } | Select-Object -First 1
    }
    if ($picked) { $synth.Voice = $picked }

    $stream = Await $synth.SynthesizeTextToStreamAsync($t) ([Windows.Media.SpeechSynthesis.SpeechSynthesisStream])
    $reader = New-Object Windows.Storage.Streams.DataReader($stream.GetInputStreamAt(0))
    Await $reader.LoadAsync([uint32]$stream.Size) ([uint32]) | Out-Null
    $bytes = New-Object byte[] ([int]$stream.Size)
    $reader.ReadBytes($bytes)
    $reader.Dispose(); $stream.Dispose(); $synth.Dispose()

    $wav = Join-Path $env:TEMP ("claude-speak-{0}.wav" -f $PID)
    [System.IO.File]::WriteAllBytes($wav, $bytes)
    Log ("sandaran $($picked.DisplayName) $($bytes.Length) bait")
    try {
        $player = New-Object System.Media.SoundPlayer $wav
        $player.PlaySync()
        $player.Dispose()
    } finally {
        Remove-Item $wav -Force -ErrorAction SilentlyContinue
    }
}

try {
    if ($FromFile) { $Text = Get-Content -LiteralPath $FromFile -Raw -Encoding UTF8 }
    if (-not $Text) { $Text = ($input | Out-String) }
    if (-not $Text -or -not $Text.Trim()) { Log 'teks kosong'; exit 0 }

    $Text = Get-CleanText $Text
    if (-not $Text) { Log 'teks kosong selepas bersih'; exit 0 }
    if ($Text.Length -gt 1500) { $Text = $Text.Substring(0, 1500) }

    try {
        Invoke-ElevenLabs $Text
    } catch {
        Log "EL langkau/gagal ($($_.Exception.Message)) - guna edge-tts $Voice"
        try {
            Invoke-EdgeTts $Text
        } catch {
            Log "edge-tts gagal ($($_.Exception.Message)) - cuba sandaran WinRT"
            Invoke-WinRtTts $Text
        }
    }
    Log 'siap'
} catch {
    Log "RALAT: $($_.Exception.Message)"
    exit 1
}
