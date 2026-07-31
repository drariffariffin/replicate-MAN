---
description: Pull semua sync repo — fleet memory & Man config. WAJIB dijalankan pada START setiap sesi.
---

# MAN SYNC PULL — Session Start Protocol

Jalankan ini **SETIAP KALI AWAL SESI** tanpa perlu disuruh:

```bash
echo "=== PULL: orca-fleet-memory ===" && cd ~/Orca/orca-fleet-memory && git pull && echo "" && echo "=== PULL: replicate-MAN (Man config) ===" && cd ~/.config/kilo && git pull 2>/dev/null || echo "(not a git repo yet)" && echo "" && echo "=== LATEST Ben context ===" && tail -30 ~/Orca/orca-fleet-memory/nodes/orcaariff/shared-context/REALTIME.md
```

Lepas pull, baca dan present:
1. Latest entries dari Ben dalam REALTIME.md
2. Status LATEST.md
3. Tanya Dr. Ariff: "Nak sambung dari sini, atau ada benda baru?"
