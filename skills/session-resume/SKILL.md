---
name: session-resume
description: Resume work on a project by reading HANDOFF.md and STATE.md from the per-project state directory and summarizing where we left off, what was pending, and what the next step is. Use at the start of a session when the user says "riprendiamo", "resume", "dov'eravamo", "continua il lavoro su X", or when returning to a project after a break.
argument-hint: "[project-slug]"
allowed-tools: Read, Bash(git status:*), Bash(git log:*), Bash(git branch:*), Bash(git remote:*), Bash(git rev-parse:*)
---

# Session Resume

Riprendi un progetto leggendo il suo stato salvato e proponi il prossimo step.

## Quando usarla

- L'utente dice "riprendiamo", "resume", "dov'eravamo", "torniamo a X".
- Inizio sessione su un progetto già conosciuto.
- L'utente chiede "a che punto sono su X?".

## Procedura

### 1. Risolvi slug

```bash
slug=$(git remote get-url origin 2>/dev/null | sed 's|.*/||;s|\.git$||')
[ -z "$slug" ] && slug=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
state_dir="$HOME/.claude/state/projects/$slug"
```

Se l'utente menziona esplicitamente un progetto diverso (es. "riprendiamo X"), usa quello slug.

### 2. Carica artefatti (in ordine di priorità)

1. `$state_dir/HANDOFF.md` — il più rilevante: snapshot dell'ultima sessione.
2. `$state_dir/STATE.md` > sezione `Now`.
3. `$state_dir/PLAN.md` — step `[ ]` non completati.
4. `$state_dir/PROJECT.md` — solo se non hai context sul progetto.
5. `$state_dir/DECISIONS.md` — ultime 2-3 sezioni datate.

Se `$state_dir` non esiste o è vuoto:
> Non trovo stato salvato per `<slug>`. Vuoi che lanci `project-bootstrap` per inizializzarlo?

### 3. Verifica stato git

```bash
git status -s
git branch --show-current
git log -3 --oneline
```

Confronta con `HANDOFF.md > Stato git`. Se diverge (es. nuovi commit non documentati, branch cambiato), segnalalo all'utente.

### 4. Riassunto in chat

Output in italiano, conciso. Formato consigliato:

```
**Resume: <slug>**

Dove eravamo: <1-2 frasi da HANDOFF.md > Task corrente>

Stato git: <branch> · <modifiche / pulito> · <push pending o no>

Prossimo step (da HANDOFF.md):
1. <step>
2. <step>
3. <step>

⚠️ <eventuali divergenze rilevate>

Procedo con (1)?
```

### 5. Attendi conferma

**Non** iniziare a eseguire automaticamente. L'utente deve confermare il prossimo step (o redirigere).

## Artefatti

- **Legge**: `HANDOFF.md`, `STATE.md`, `PLAN.md`, `PROJECT.md`, `DECISIONS.md` (solo recenti)
- **Scrive**: niente (lettura pura)

## Note

- Se `HANDOFF.md` è vecchio di più di 7 giorni, segnalalo — il context potrebbe essere stantio.
- Se i 3 step in `HANDOFF.md` non sono più rilevanti (perché branch/codebase sono cambiati molto), suggerisci `workflow-plan` per rifare il piano.
