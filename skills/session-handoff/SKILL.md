---
name: session-handoff
description: Snapshot the current session state into HANDOFF.md so the next session can resume cleanly. Use when the user says "chiudiamo", "stop", "ci risentiamo domani", at the end of a long session, or when context is getting heavy and you need to checkpoint progress.
---

# Session Handoff

Scrivi uno snapshot conciso della sessione corrente in `~/.claude/state/projects/<slug>/HANDOFF.md` per permettere a `session-resume` di riprendere dove ci siamo lasciati.

## Quando usarla

- L'utente dice "chiudiamo", "stop", "a domani", "ci sentiamo poi".
- Fine sessione lunga / context window pesante.
- Cambio di focus a un altro progetto.

## Procedura

### 1. Risolvi slug

```bash
slug=$(git remote get-url origin 2>/dev/null | sed 's|.*/||;s|\.git$||')
[ -z "$slug" ] && slug=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
state_dir="$HOME/.claude/state/projects/$slug"
mkdir -p "$state_dir"
```

### 2. Raccogli lo stato

Prima di scrivere, controlla:

```bash
git -C "$(pwd)" status -s     # modifiche non committate
git -C "$(pwd)" branch --show-current
git -C "$(pwd)" log -3 --oneline
```

### 3. Scrivi HANDOFF.md

**Overwrite completo** (un solo handoff attivo). Formato:

```markdown
# Handoff: <slug>

> Saved: <ISO timestamp>  ·  Branch: <branch>  ·  Last commit: <sha shortlog>

## Task corrente
<1-2 frasi: cosa stavamo facendo>

## Stato git
- Branch: <name>
- Modifiche non committate: <count file + lista breve, o "nessuna">
- Push pending: <yes/no>

## File aperti / toccati di recente
- `path/to/file:line` — <nota>
- ...

## Prossimi 3 step
1. <step concreto>
2. <step concreto>
3. <step concreto>

## Domande aperte / blocker
- <domanda> — chi/cosa serve per rispondere
- <blocker> — workaround temporaneo se c'è

## Riferimenti
- `PLAN.md` step corrente: <n>
- Decisioni recenti rilevanti: <link a sezione di DECISIONS.md se utile>
```

### 4. Update STATE.md > Now

Refresh del blocco `Now` di `STATE.md` con timestamp handoff:
```
- Ultima sessione: <ISO timestamp> (handoff)
```

### 5. Conferma all'utente

Una riga in chat:
> Handoff salvato in `~/.claude/state/projects/<slug>/HANDOFF.md`. Alla prossima sessione usa `session-resume`.

## Artefatti

- **Scrive**: `HANDOFF.md` (overwrite), `STATE.md > Now` (refresh timestamp)
- **Legge**: `STATE.md`, `PLAN.md`, `DECISIONS.md`

## Note

- Sii sintetico — l'handoff deve essere leggibile in 30 secondi.
- Non duplicare tutto `STATE.md`: solo il necessario per ripartire.
- Se non ci sono modifiche significative dall'ultimo handoff, **suggerisci di non sovrascrivere** e chiedi conferma.
