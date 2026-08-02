# speak-hook.ps1 - Hook Stop untuk Claude Code.
# Baca JSON dari stdin, ambil mesej assistant terakhir daripada transcript,
# dan bacakan ia kuat guna suara Melayu.
# Proses suara dilancarkan TERPISAH (via WMI) supaya ia tidak dibunuh
# bersama pokok proses hook apabila hook tamat.
$ErrorActionPreference = 'SilentlyContinue'

$log = Join-Path $PSScriptRoot 'speak.log'
function Log($m) { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $m" | Add-Content -LiteralPath $log -Encoding UTF8 }

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { Log 'stdin kosong'; exit 0 }

try { $payload = $raw | ConvertFrom-Json } catch { Log 'JSON tak sah'; exit 0 }
$transcript = $payload.transcript_path
if (-not $transcript -or -not (Test-Path $transcript)) { Log "transcript tiada: $transcript"; exit 0 }

# Cari entri assistant terakhir yang ada teks
$text = $null
$lines = @(Get-Content -LiteralPath $transcript -Encoding UTF8)
for ($i = $lines.Count - 1; $i -ge 0; $i--) {
    if (-not $lines[$i]) { continue }
    try { $entry = $lines[$i] | ConvertFrom-Json } catch { continue }
    if ($entry.type -ne 'assistant') { continue }
    $parts = @($entry.message.content | Where-Object { $_.type -eq 'text' -and $_.text })
    if ($parts.Count -gt 0) {
        $text = ($parts | ForEach-Object { $_.text }) -join ' '
        break
    }
}
if (-not $text -or -not $text.Trim()) { Log 'tiada teks assistant'; exit 0 }

# Hentikan sebarang bacaan yang masih berjalan
$pidFile = Join-Path $env:TEMP 'claude-speak.pid'
if (Test-Path $pidFile) {
    $old = Get-Content $pidFile
    if ($old) { Stop-Process -Id ([int]$old) -Force -ErrorAction SilentlyContinue }
}

$speaker = Join-Path $PSScriptRoot 'speak.ps1'
$txtFile = Join-Path $env:TEMP 'claude-speak-text.txt'
Set-Content -LiteralPath $txtFile -Value $text -Encoding UTF8

$cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Sta -WindowStyle Hidden -File `"$speaker`" -FromFile `"$txtFile`""

# Lancar terpisah melalui WMI: proses jadi anak WmiPrvSE, bukan anak hook,
# jadi ia selamat walaupun Claude Code bunuh pokok proses hook.
$newPid = $null
try {
    $res = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $cmd } -ErrorAction Stop
    if ($res.ReturnValue -eq 0) { $newPid = $res.ProcessId; Log "WMI lancar PID $newPid" }
    else { Log "WMI gagal, ReturnValue=$($res.ReturnValue)" }
} catch { Log "WMI ralat: $($_.Exception.Message)" }

if (-not $newPid) {
    $proc = Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -PassThru -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Sta', '-File', $speaker, '-FromFile', $txtFile
    )
    $newPid = $proc.Id
    Log "fallback Start-Process PID $newPid"
}

Set-Content -LiteralPath $pidFile -Value $newPid
exit 0
