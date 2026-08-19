# Sistem Suara Claude Code — Nota Rujukan

Dikemas kini: 2026-08-20

## Keadaan sekarang

Setiap jawapan Claude Code dibaca kuat. Suara aktif: **Osman** (`ms-MY-OsmanNeural`).

Rantaian **tiga lapis** — kalau satu gagal, ia jatuh ke bawah secara automatik:

| # | Lapis | Bila digunakan | Status |
|---|---|---|---|
| 1 | **ElevenLabs** | Bila kunci API + `voiceId` diisi | Menunggu kunci |
| 2 | **edge-tts** | Lalai sekarang — Osman/Yasmin | **Aktif** |
| 3 | **WinRT OneCore** | Kalau internet putus | **Tidak berfungsi** (lihat bawah) |

## Fail

| Fail | Fungsi |
|---|---|
| `speak.ps1` | Enjin utama — rantaian tiga lapis |
| `speak-hook.ps1` | Dipanggil oleh hook `Stop`; baca transkrip, lancar `speak.ps1` |
| `voice-config.json` | Tetapan suara |
| `setup-elevenlabs.ps1` | Jalankan sekali bila kunci dah dapat |
| `speak.log` | Rekod setiap kali bercakap — periksa sini kalau senyap |
| `.elevenlabs-key` | Kunci disulit (DPAPI, pengguna ini sahaja). Dicipta oleh skrip setup |

Hook didaftarkan dalam `C:\Users\User\.claude\settings.json` di bawah `hooks.Stop`.

## Bila kunci ElevenLabs sampai

Satu arahan sahaja:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\User\.claude\scripts\setup-elevenlabs.ps1" -ApiKey "sk_xxxxx"
```

Ia akan: simpan kunci (disulit) → sahkan dengan ElevenLabs → senaraikan semua suara akaun →
cari **Afifah** (pilihan dalam `voice-config.json`); kalau tiada dalam akaun, ia cari dalam
**Voice Library** dan tambahkan → tulis `voiceId` ke config → uji bunyi.

Nak suara lain: `-VoiceName "Nora"`. Nak tengok senarai sahaja dahulu: `-ListOnly`.

## Tukar suara

**Osman ⇄ Yasmin** — edit `voice-config.json`, tukar `edgeVoice`:
- `ms-MY-OsmanNeural` — lelaki
- `ms-MY-YasminNeural` — perempuan
- `id-ID-ArdiNeural` / `id-ID-GadisNeural` — Indonesia (loghat berbeza)

Itu sahaja pilihan Melayu dalam edge-tts — 2 daripada 322 suara.

**Paksa edge-tts walaupun ada kunci EL:** tukar `provider` kepada `"edge"`.

## Matikan suara

Buang blok `hooks` dalam `C:\Users\User\.claude\settings.json`, atau taip `/hooks` dalam Claude Code.

## Kalau senyap

1. Baca `speak.log` — setiap percubaan direkod dengan sebab kegagalan.
2. Uji terus: `powershell -File speak.ps1 -Text "ujian"`
3. Perlu internet — edge-tts dan ElevenLabs kedua-duanya dalam talian.

## Jurang yang belum ditutup

PC ini **tiada pakej bahasa Melayu Windows**. Registry OneCore hanya ada David/Mark/Zira (English),
jadi lapis 3 (sandaran luar talian) tidak akan berfungsi — kalau internet putus, suara terus mati.

Untuk membaikinya perlukan hak **Administrator**:

```powershell
Install-Language ms-MY
```

Guna shortcut **PowerShell** di Desktop (ia sudah ditetapkan run-as-admin). Selepas itu suara
`Microsoft Rizwan` (ms-MY) sepatutnya muncul, dan lapis 3 menjadi jaring keselamatan sebenar.
