---
description: Push semua perubahan ke sync repo. WAJIB dijalankan pada AKHIR setiap sesi.
---

# MAN SYNC PUSH — Session End Protocol

Jalankan ini **SETIAP KALI AKHIR SESI** — auto detect apa yang berubah dan push:

```bash
echo "=== PUSH: orca-fleet-memory ==="
cd ~/Orca/orca-fleet-memory
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo "No changes to push"
else
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
  git add -A && git commit -m "sync(man): $TIMESTAMP" && git push && echo "Pushed OK"
fi

echo ""
echo "=== PUSH: replicate-MAN (Man config) ==="
cd ~/.config/kilo 2>/dev/null || { echo "Not a git repo"; exit 0; }
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo "No changes to push"
else
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
  git add -A && git commit -m "sync(man): $TIMESTAMP" && git push && echo "Pushed OK"
fi

echo ""
echo "=== Sync complete ==="
```
