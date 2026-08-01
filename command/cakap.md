---
description: Sebut teks guna suara Osman (ms-MY-OsmanNeural) — TTS Melayu lelaki
---

# CAKAP — Suara Osman TTS

Guna script `~/say_osman.ps1` (laluan: `$env:USERPROFILE\.config\kilo\say_osman.ps1`).

## Cara guna

Bila user taip `/cakap <teks>`, jalankan:
```powershell
. "$env:USERPROFILE\.config\kilo\say_osman.ps1" "<teks>"
```

Contoh:
- `/cakap Assalamualaikum` → sebut "Assalamualaikum" dengan suara Osman
- `/cakap Projek OrcaHub dah siap deploy` → sebut dengan suara Osman

## Voice settings
- Voice: `ms-MY-OsmanNeural` (lelaki Melayu)
- Rate: -10% (0.9x — lebih natural, tak laju sangat)
- Guna `edge-tts` Python CLI (sama macam MacBook Dr. Ariff)
