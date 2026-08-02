# PTT Melayu — Tekan F12 untuk mula rakam, transkrip BM, dan paste
param(
    [int]$Duration = 15,    # Max recording duration in seconds
    [string]$TempDir = "$env:TEMP"
)

$recordingFile = Join-Path $TempDir "ptt_melayu_recording.wav"
$scriptDir = "$env:USERPROFILE\.config\kilo"
$pythonScript = Join-Path $scriptDir "whisper_melayu.py"

Remove-Item $recordingFile -Force -ErrorAction SilentlyContinue

Write-Host "Rakam $Duration saat... Cakap sekarang dalam Bahasa Melayu."
Write-Host "Tekan Ctrl+C untuk berhenti awal."

ffmpeg -y -f dshow -i audio="Microphone (USB Audio and HID)" -t $Duration -ac 1 -ar 16000 $recordingFile 2>$null

if (Test-Path $recordingFile) {
    $size = (Get-Item $recordingFile).Length
    Write-Host "Rakaman selesai: $([math]::Round($size/1024))KB"
    
    Write-Host "Transkrip dengan Whisper..."
    $text = python $pythonScript $recordingFile 2>$null
    
    if ($text) {
        $text = $text.Trim()
        Write-Host "Hasil: $text"
        Set-Clipboard -Value $text
        Write-Host "Dah copy ke clipboard. Ctrl+V untuk paste."
    } else {
        Write-Host "Transkripsi kosong."
    }
    
    Remove-Item $recordingFile -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "Rakaman gagal. Pastikan mic tersedia."
}
