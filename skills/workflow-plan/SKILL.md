---
name: workflow-plan
description: Produce a structured numbered plan for non-trivial multi-step tasks. Use when the user asks to "piano", "plan this", "fai un piano", or before starting any task that touches more than 2-3 files or requires coordinated changes. Maps the codebase via the code-explorer subagent to keep main context light, then writes PLAN.md in the per-project state directory.
argument-hint: <task description>
---

# Workflow Plan

Produce a concrete plan for a non-trivial task and salvalo in `~/.claude/state/projects/<slug>/PLAN.md`.

## Quando usarla

- Task che tocca 3+ file o richiede modifiche coordinate
- Feature nuova non triviale
- Refactor che spazia su più moduli
- L'utente dice "piano", "plan this", "fai un piano", "come affronteresti X"

**Non** serve per: fix di 1-2 righe, query di lettura, domande Q&A.

## Procedura

### 1. Risolvi lo slug del progetto

```bash
slug=$(git remote get-url origin 2>/dev/null | sed 's|.*/||;s|\.git$||')
[ -z "$slug" ] && slug=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
state_dir="$HOME/.claude/state/projects/$slug"
mkdir -p "$state_dir"
```

### 2. Carica contesto esistente

Leggi (se esistono):
- `$state_dir/PROJECT.md` — capire stack e goal
- `$state_dir/STATE.md` — capire dove eravamo arrivati
- `$state_dir/DECISIONS.md` — vincoli architetturali già presi

### 3. Mappa codebase (delegato)

Per task non triviali lancia il subagent `code-explorer` con una richiesta mirata. Esempio:

> "Mappa i file rilevanti per implementare X. Cerca: pattern esistenti di Y, punti di estensione, test esistenti, dipendenze tra moduli. Report strutturato sotto 300 parole."

Salta lo step solo se il target è ovvio (path esplicito dell'utente).

### 4. Scrivi il piano

Crea/aggiorna `$state_dir/PLAN.md` con questo formato:

```markdown
# Plan: <titolo task>

> Created: <ISO timestamp>  ·  Project: <slug>

## Goal
<1-2 frasi: cosa si vuole ottenere>

## Context
<2-3 bullet: stato attuale rilevante, vincoli noti>

## Steps
1. [ ] <step concreto> — `<file:line se noto>`
2. [ ] <step concreto> — `<file:line>`
3. [ ] ...

## Verification
- <come si verifica che il piano è completo: test, comando, comportamento osservabile>

## Risks / Open questions
- <risk> — mitigation
- <question> — chi/quando decide
```

Step regole:
- Ogni step **eseguibile in isolamento** e verificabile.
- Massimo 7-10 step. Se ne servono di più, scomponi in sub-piani.
- Riferimenti file:line dove possibile.
- Niente step generici tipo "implementa la feature" — sii specifico.

### 5. Output utente

Presenta il piano in chat (riassunto + link al file). Chiedi conferma prima di passare a `workflow-execute`:

> Piano scritto in `~/.claude/state/projects/<slug>/PLAN.md`. Approvi? Procedo con `workflow-execute`?

## Artefatti

- **Legge**: `PROJECT.md`, `STATE.md`, `DECISIONS.md`
- **Scrive**: `PLAN.md` (overwrite — un solo piano attivo per progetto)

## Note

- Se `PLAN.md` esiste già con step non completati, **non sovrascrivere senza chiedere**. Mostra il piano esistente e chiedi se completare/archiviare/sostituire.
- Per archiviare un piano completato: rinomina in `PLAN-<ISO-date>.md` o sposta in `archive/` sotto `$state_dir/`.
