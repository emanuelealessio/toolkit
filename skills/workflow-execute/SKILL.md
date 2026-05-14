---
name: workflow-execute
description: Execute an approved plan step-by-step, updating STATE.md after each step and logging non-trivial decisions in DECISIONS.md. Use after workflow-plan has produced a PLAN.md and the user has approved it, or when the user says "esegui il piano", "implement the plan", "vai avanti col piano".
---

# Workflow Execute

Esegui `PLAN.md` step-by-step, mantenendo `STATE.md` e `DECISIONS.md` aggiornati per la continuità delle sessioni.

## Quando usarla

- Dopo che `workflow-plan` ha prodotto un `PLAN.md` approvato dall'utente.
- L'utente dice "esegui", "implementa", "go", "procedi col piano".

Se non esiste `PLAN.md`, ferma e suggerisci `workflow-plan`.

## Procedura

### 1. Risolvi slug e carica PLAN.md

```bash
slug=$(git remote get-url origin 2>/dev/null | sed 's|.*/||;s|\.git$||')
[ -z "$slug" ] && slug=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
state_dir="$HOME/.claude/state/projects/$slug"
```

Leggi `$state_dir/PLAN.md`. Identifica il primo step non spuntato (`[ ]`).

### 2. Esegui uno step alla volta

Per ogni step:

1. Annuncia in chat quale step stai per fare (una riga).
2. Esegui le modifiche necessarie. Per esplorazioni o test verbose, delega a `code-explorer` o `test-runner`.
3. Verifica (test, build, lint se applicabili).
4. Spunta lo step nel `PLAN.md` (`[ ]` → `[x]`).
5. Aggiorna `STATE.md` (vedi sotto).
6. Se è stata presa una decisione non triviale, appendi a `DECISIONS.md`.

**Ferma dopo ogni step e chiedi conferma** prima di passare al successivo, a meno che l'utente abbia detto esplicitamente "vai fino in fondo" o simili. Lo step può essere lungo — la conferma costa poco.

### 3. Aggiorna STATE.md

Formato `STATE.md` (overwrite del blocco "Now", append in "History"):

```markdown
# State: <slug>

## Now
- Task: <PLAN.md titolo>
- Step corrente: <numero/titolo prossimo step da fare>
- Branch: <current git branch>
- Ultima sessione: <ISO timestamp>

## History
## 2026-05-14T15:30 — Step 3 completato
- Modifiche: `src/foo.py:42-58`, `tests/test_foo.py:10`
- Test: 12/12 verdi
- Note: <se rilevanti>
```

`Now` viene riscritto. `History` cresce in append-only con sezioni H2 datate.

### 4. Aggiorna DECISIONS.md (solo se serve)

Append-only. Una sezione H2 datata per decisione architetturale non triviale:

```markdown
## 2026-05-14T15:32 — Scelta libreria HTTP: httpx
- Contesto: serve client async con timeout fine-grained
- Alternative: aiohttp, requests+threading
- Motivo: httpx supporta sync+async same API, più semplice da testare
- Trade-off: dipendenza extra (~5MB)
```

Solo per **decisioni**, non per ogni edit. Se è ovvio o forzato, salta.

### 5. Completamento

Quando tutti gli step sono `[x]`:
- Aggiorna `STATE.md > Now > Task` a "completato".
- Suggerisci `git-commit` o `git-pr` se applicabile.
- **Non** archiviare automaticamente `PLAN.md` — chiedi all'utente.

## Artefatti

- **Legge**: `PLAN.md`, `PROJECT.md`, `STATE.md`, `DECISIONS.md`
- **Scrive**: `STATE.md` (Now overwrite + History append), `DECISIONS.md` (append), `PLAN.md` (spunte)

## Subagent

- `code-explorer` per ri-leggere file/aree non già in contesto.
- `test-runner` per eseguire la suite del progetto e ottenere pass/fail compatto.

## Note

- Se uno step fallisce (test rossi, build broken), **fermati**. Non andare avanti col piano. Aggiorna `STATE.md` con il blocker e chiedi all'utente come procedere (fix immediato, modifica del piano, abbandono).
- Se durante l'esecuzione emerge che il piano è sbagliato, fermati e suggerisci di tornare a `workflow-plan`.
