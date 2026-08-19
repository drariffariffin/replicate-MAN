# setup-elevenlabs.ps1 - Jalankan SEKALI bila kunci ElevenLabs dah dapat.
# Ia akan: simpan kunci (disulit DPAPI), senaraikan semua suara dalam akaun,
# biar anda pilih satu, tulis ke voice-config.json, dan uji bunyi.
#
# Guna:  powershell -ExecutionPolicy Bypass -File setup-elevenlabs.ps1 -ApiKey "sk_xxxxx"
#        powershell -ExecutionPolicy Bypass -File setup-elevenlabs.ps1 -ApiKey "sk_xxx" -VoiceName "Nora"
#        powershell -ExecutionPolicy Bypass -File setup-elevenlabs.ps1 -ListOnly
param(
    [string]$ApiKey,
    [string]$VoiceName,
    [switch]$ListOnly
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$keyFile = Join-Path $PSScriptRoot '.elevenlabs-key'
$cfgPath = Join-Path $PSScriptRoot 'voice-config.json'
$cfg = Get-Content -LiteralPath $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $VoiceName -and $cfg.elevenLabs.preferredVoiceName) { $VoiceName = $cfg.elevenLabs.preferredVoiceName }

# ---------- 1. Kunci ----------
if ($ApiKey) {
    $ApiKey = $ApiKey.Trim()
    ($ApiKey | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString) |
        Set-Content -LiteralPath $keyFile -Encoding ascii
    Write-Host "Kunci disimpan (disulit untuk pengguna ini sahaja): $keyFile" -ForegroundColor Green
} else {
    if (-not (Test-Path $keyFile)) { throw "Tiada kunci tersimpan. Jalankan semula dengan -ApiKey 'sk_xxxxx'" }
    $sec = Get-Content -LiteralPath $keyFile -Raw | ConvertTo-SecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    try { $ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    Write-Host "Guna kunci tersimpan." -ForegroundColor DarkGray
}

$H = @{ 'xi-api-key' = $ApiKey }

# ---------- 2. Sahkan kunci ----------
try {
    $me = Invoke-RestMethod -Uri 'https://api.elevenlabs.io/v1/user' -Headers $H
    Write-Host "Kunci SAH. Tier: $($me.subscription.tier)  |  Baki aksara: $($me.subscription.character_count)/$($me.subscription.character_limit)" -ForegroundColor Green
} catch {
    throw "Kunci DITOLAK oleh ElevenLabs: $($_.Exception.Message)"
}

# ---------- 3. Senarai suara ----------
$voices = (Invoke-RestMethod -Uri 'https://api.elevenlabs.io/v1/voices' -Headers $H).voices
Write-Host ""
Write-Host "--- $($voices.Count) suara dalam akaun anda ---" -ForegroundColor Cyan
$i = 0
$voices | ForEach-Object {
    $i++
    $lbl = $_.labels
    $desc = @()
    if ($lbl.gender)   { $desc += $lbl.gender }
    if ($lbl.accent)   { $desc += $lbl.accent }
    if ($lbl.language) { $desc += $lbl.language }
    "{0,3}. {1,-28} {2,-12} {3}" -f $i, $_.name, $_.category, ($desc -join ', ')
}

if ($ListOnly) { return }

# ---------- 4. Pilih suara ----------
$picked = $null
if ($VoiceName) {
    $picked = $voices | Where-Object { $_.name -eq $VoiceName } | Select-Object -First 1
    if (-not $picked) { $picked = $voices | Where-Object { $_.name -like "*$VoiceName*" } | Select-Object -First 1 }

    # Belum ada dalam akaun? Cari dalam Voice Library awam dan tambah.
    if (-not $picked) {
        Write-Host "'$VoiceName' tiada dalam akaun. Mencari dalam Voice Library..." -ForegroundColor Yellow
        try {
            $shared = (Invoke-RestMethod -Uri "https://api.elevenlabs.io/v1/shared-voices?page_size=100&search=$([uri]::EscapeDataString($VoiceName))" -Headers $H).voices
        } catch { $shared = @() }
        if (-not $shared -or $shared.Count -eq 0) { throw "'$VoiceName' tak dijumpai dalam akaun mahupun Voice Library. Jalankan -ListOnly untuk lihat senarai akaun." }

        Write-Host "Jumpa $($shared.Count) padanan dalam Voice Library:" -ForegroundColor Cyan
        $shared | Select-Object -First 10 | ForEach-Object {
            "    {0,-28} {1}" -f $_.name, (@($_.language, $_.accent, $_.gender) -ne $null -join ', ')
        }
        $cand = $shared | Where-Object { $_.name -eq $VoiceName } | Select-Object -First 1
        if (-not $cand) { $cand = $shared | Select-Object -First 1 }

        Write-Host "Menambah '$($cand.name)' ke akaun anda..." -ForegroundColor Yellow
        $addUri = "https://api.elevenlabs.io/v1/voices/add/$($cand.public_owner_id)/$($cand.voice_id)"
        $null = Invoke-RestMethod -Method Post -Uri $addUri -Headers $H `
            -ContentType 'application/json' -Body (@{ new_name = $cand.name } | ConvertTo-Json)

        $voices = (Invoke-RestMethod -Uri 'https://api.elevenlabs.io/v1/voices' -Headers $H).voices
        $picked = $voices | Where-Object { $_.name -like "*$($cand.name)*" } | Select-Object -First 1
        if (-not $picked) { throw "Gagal tambah '$($cand.name)' ke akaun." }
        Write-Host "Berjaya ditambah." -ForegroundColor Green
    }
} else {
    $picked = $voices | Where-Object { $_.category -eq 'cloned' } | Select-Object -First 1
    if (-not $picked) { $picked = $voices | Select-Object -First 1 }
}
Write-Host ""
Write-Host "Dipilih: $($picked.name)  (id: $($picked.voice_id), kategori: $($picked.category))" -ForegroundColor Yellow

# ---------- 5. Tulis config ----------
$cfg = Get-Content -LiteralPath $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json
$cfg.elevenLabs.voiceId = $picked.voice_id
$cfg.provider = 'auto'
$cfg | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $cfgPath -Encoding UTF8
Write-Host "voice-config.json dikemas kini." -ForegroundColor Green

# ---------- 6. Uji bunyi ----------
Write-Host ""
Write-Host "Menguji suara..." -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'speak.ps1') -Text "Assalamualaikum Doktor Ariff. Suara ini sudah berjaya disambungkan ke Claude Code."
$log = Join-Path $PSScriptRoot 'speak.log'
if (Test-Path $log) { Get-Content $log | Select-Object -Last 3 }
Write-Host ""
Write-Host "SIAP. Mulai sekarang setiap jawapan Claude Code akan guna suara ini." -ForegroundColor Green
