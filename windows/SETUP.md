# Kilo Windows Setup Guide

**PC:** Windows — username `ariff`
**Fleet repo:** `C:\Users\ariff\Orca\orca-fleet-memory\`

---

## Step 1: Install Prerequisites

### Git
Download & install: https://git-scm.com/download/win
- Pilih "Git Bash" (recommended terminal)
- Default options OK

### Node.js + npm
Download & install LTS: https://nodejs.org/
- Pastikan tick "Add to PATH"

### Bun (optional tapi recommended)
```powershell
powershell -c "irm bun.sh/install.ps1 | iex"
```

### GitHub CLI
```powershell
winget install --id GitHub.cli
```

---

## Step 2: Install VS Code + Kilo

1. Download VS Code: https://code.visualstudio.com/
2. Install → buka VS Code
3. `Ctrl+Shift+X` → search **"Kilo Code"**
4. Klik dropdown arrow sebelah **Install** → **Install Pre-Release Version**

### PowerShell PATH (PENTING utk Windows)
1. **Edit system environment variables** → **Environment Variables**
2. System variables → **Path** → **Edit** → **New**
3. Add: `C:\Windows\System32\WindowsPowerShell\v1.0\`
4. OK & restart VS Code

---

## Step 3: Setup GitHub + Clone Repos

```bash
gh auth login
# Pilih: GitHub.com → HTTPS → Login with browser
```

### Clone fleet memory repo
```bash
mkdir -p C:/Users/ariff/Orca
cd C:/Users/ariff/Orca
git clone https://github.com/syrimo/orca-fleet-memory.git
```

### Clone project repos (ikut keperluan)
```bash
# OrcaClinic (kalau nak)
git clone https://github.com/syrimo/orcaclinic.git
```

---

## Step 4: Copy Kilo Config Files

Copy semua files dalam folder `kilo-windows-setup/` ke PC:

```
kilo-windows-setup/
├── kilo.jsonc          → C:\Users\ariff\.config\kilo\kilo.jsonc
├── commands/
│   ├── man-sync-write.md → C:\Users\ariff\.config\kilo\command\man-sync-write.md
│   ├── man-sync-read.md  → C:\Users\ariff\.config\kilo\command\man-sync-read.md
│   ├── sync.md           → C:\Users\ariff\.config\kilo\command\sync.md
│   └── orca-recall.md    → C:\Users\ariff\.config\kilo\command\orca-recall.md
└── package.json        → C:\Users\ariff\.config\kilo\package.json
```

Buat folder dulu:
```powershell
mkdir C:\Users\ariff\.config\kilo\command
```

Lepas copy, install npm dependencies:
```bash
cd C:/Users/ariff/.config/kilo && npm install
```

---

## Step 5: Setup DeepSeek Provider (Model)

Dalam VS Code dengan Kilo extension:

1. Klik gear icon ⚙️ di Kilo sidebar → **Settings**
2. Pergi tab **Providers**
3. Add provider → **DeepSeek** (atau custom OpenAI-compatible endpoint)
4. Masukkan API key DeepSeek kau
5. Set model: `deepseek/deepseek-v4-pro` (atau auto-detect)

ATAU guna Custom Provider kalau pakai OpenRouter/z.ai:

**Provider type:** OpenAI Compatible
**Base URL:** `https://api.openrouter.ai/v1` (OpenRouter) atau endpoint z.ai
**API Key:** `<api-key-kau>`
**Model:** `deepseek/deepseek-v4-pro`

---

## Step 6: Verify Setup

Test dalam VS Code Kilo chat:

```
/man-sync-read
```

Seharusnya pull latest dari fleet repo dan tunjuk update dari Ben.

Test:
```
/sync
```

Seharusnya baca LATEST.md dan present summary.

---

## Step 7: CLAUDE.md (Kalau guna OpenClaude juga)

Kalau PC tu ada OpenClaude, copy `CLAUDE.md` dari Mac ke:
```
C:\Users\ariff\CLAUDE.md
```

---

## How to share files ke Windows PC

Guna thumbdrive, network share, atau cloud (Google Drive).

---

## Paths Reference

| Mac | Windows |
|---|---|
| `/Users/ariffariffin/` | `C:\Users\ariff\` |
| `~/Orca/orca-fleet-memory/` | `C:\Users\ariff\Orca\orca-fleet-memory\` |
| `~/.config/kilo/` | `C:\Users\ariff\.config\kilo\` |
| `/tmp/` | `C:\Users\ariff\AppData\Local\Temp\` |
| `/Applications/` | `C:\Program Files\` |
