---
description: Man tulis latest exchange ke shared sync file dan push ke git
---

Selepas setiap exchange penting dengan Dr. Ariff, jalankan ini (ganti placeholder dengan ringkasan sebenar):

```bash
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
REALTIME="$HOME/Orca/orca-fleet-memory/nodes/orcaariff/shared-context/REALTIME.md"
echo "" >> "$REALTIME"
echo "[$TIMESTAMP MAN-USER] <ringkasan soalan Dr. Ariff, max 200 chars>" >> "$REALTIME"
echo "[$TIMESTAMP MAN] <ringkasan reply Man, max 300 chars>" >> "$REALTIME"
cd ~/Orca/orca-fleet-memory && git add nodes/orcaariff/shared-context/REALTIME.md && git commit -m "sync(man): $TIMESTAMP" && git push
```

Ben akan auto-pull dan nampak update ini dalam response seterusnya.
