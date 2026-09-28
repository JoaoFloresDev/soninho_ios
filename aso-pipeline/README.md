# ASO Pipeline — Sunrise Alarm Clock: Wake Up

App ID: `6758740138`
Bundle ID: `com.gambitstudio.soninho`
Primary locale: `en-US`
Baseline at init: 4.4 downloads/dia
Created: 2026-09-27

Estrutura e workflow: ver `~/Documents/GambitStudio/aso-pipeline-template/README.md`.
Aprendizados cross-app: ver `~/Documents/GambitStudio/aso_cross_project_learnings.md` ANTES de começar iter-01.

## Quick start

```bash
# 1) Sync current/ from ASC live state
./scripts/verify_current.sh

# 2) Start first iteration
./scripts/new_iteration.sh text en-US keywords

# 3) Research → write proposed/ → validate → deploy
./scripts/validate_proposed.sh iterations/<iter_id>
./scripts/deploy.sh iterations/<iter_id>
```
