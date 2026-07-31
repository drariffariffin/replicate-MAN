# AGENTS.md — Kilo (Man) Instructions

## Session Start Protocol (MANDATORY)
Before any task — pull all sync repos to get latest context:
```
/man-sync-pull
```

## Session End Protocol (MANDATORY)  
Before exiting — push all changes to sync repos:
```
/man-sync-push
```

## Sync Repos
- `~/Orca/orca-fleet-memory` — shared context Ben↔Man
- `~/.config/kilo` — Man's config & commands (tracked by `replicate-MAN` repo)

## Rules
- SOP ini embedded — jangan tunggu disuruh oleh Dr. Ariff
- Pull start, push end — setiap sesi
- Kalau terlepas, Ben atau Dr. Ariff akan tegur
