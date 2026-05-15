---
name: learn-codebase
description: Explore a project and distill its conventions, stack-specifics, commands, and gotchas into PATTERNS.md. Use when arriving cold on a repo, after project-bootstrap, or when the user says "impara questo progetto", "learn this codebase", "studia il repo". Re-runnable to refresh stale patterns. Delegates the heavy mapping to the code-explorer subagent.
allowed-tools: Read, Write, Grep, Glob, Bash(git remote get-url:*), Bash(git rev-parse:*), Bash(ls:*), Bash(find:*)
---

# Learn Codebase

Esplora un progetto e scrive un knowledge snapshot in `PATTERNS.md` che sopravvive alle sessioni. Loop di apprendimento: questa è la fase di **cattura strutturale**. La fase di cattura runtime è `retro`. Entrambi vengono riletti da `session-resume`.

## Quando usarla

- Subito dopo `project-bootstrap` su un repo nuovo (lo bootstrap lo suggerisce).
- Su un repo esistente al primo lavoro serio (l'utente dice "studia il repo", "impara questo progetto").
- Periodicamente per refresh quando le convenzioni evolvono (overwrite consapevole).

**Non** serve per: fix one-shot di 1 riga, query Q&A, repo che già conosci bene in questa sessione.

## Procedura

### 1. Risolvi slug e state dir

```bash
slug=$(git remote get-url origin 2>/dev/null | sed 's|.*/||;s|\.git$||')
[ -z "$slug" ] && slug=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
state_dir="$HOME/.claude/state/projects/$slug"
mkdir -p "$state_dir"
```

Se `$state_dir/PATTERNS.md` esiste già:
> PATTERNS.md esiste per `<slug>` (last update: <data>). Aggiorno (overwrite), incrementale (merge sezione per sezione), o annullo?

### 2. Mappa il progetto via subagent

Delega a `code-explorer` con una richiesta strutturata. Esempio:

> "Mappa il progetto in <cwd>. Cerca e riporta:
> - Lingua/stack principale e versione (da pyproject.toml/package.json/Cargo.toml/go.mod ecc.)
> - Framework principale (FastAPI/Express/Rails/Phoenix/Gin/...) — guarda dependencies + entry point
> - Test framework e directory dei test
> - Build/deploy entry point (Makefile, scripts in package.json, CI workflow)
> - Layout directory top-level (src/, lib/, app/, ecc.) — pattern di organizzazione
> - Convenzioni di naming visibili (snake_case vs camelCase, plurale/singolare, prefissi)
> - File di config notevoli (.env.example, config/, settings.py, ecc.)
> - Eventuali README/CONTRIBUTING/ARCHITECTURE in repo, prime 50 righe se rilevanti
> Output compatto, ~400 parole max."

### 3. Estrai i comandi reali

Cerca i comandi che effettivamente girano nel progetto, non quelli "tipici":

```bash
# package.json scripts
[ -f package.json ] && python3 -c "import json; d=json.load(open('package.json')); print('\n'.join(f'{k}: {v}' for k,v in d.get('scripts',{}).items()))" 2>/dev/null

# Makefile targets
[ -f Makefile ] && grep -E '^[a-zA-Z_-]+:' Makefile | head -20

# pyproject.toml scripts / tool config
[ -f pyproject.toml ] && grep -E '^\[(tool|project\.scripts)' pyproject.toml

# Justfile / Taskfile
[ -f justfile ] && grep -E '^[a-zA-Z_-]+:' justfile
[ -f Taskfile.yml ] && grep '^  [a-zA-Z_-]*:$' Taskfile.yml
```

### 4. Scrivi PATTERNS.md

Overwrite (un solo snapshot attivo). Formato:

```markdown
# Patterns: <slug>

> Captured: <ISO timestamp>  ·  By: learn-codebase

## Stack
- Linguaggio: <es. Python 3.12>
- Framework: <es. FastAPI + Pydantic v2>
- Database: <se rilevato>
- Test: <es. pytest, in tests/, marker async>
- Build: <es. uv, pnpm, cargo>
- Container: <Docker presente sì/no, base image>

## Layout
- `src/` — codice applicativo
- `tests/` — test (struttura: <piatta / per-module / mirror src/>)
- `<altre dir notevoli>` — <ruolo>

## Convenzioni
- Naming file: <snake_case.py / kebab-case.ts / ...>
- Naming funzioni: <...>
- Import style: <relative / absolute, alias se presenti>
- Docstring style: <google / numpy / sphinx / none>
- Type hints: <obbligatorie / opzionali / nessuna>

## Comandi reali (verificati da config)
- Test: `<comando esatto>`
- Lint: `<comando>` (o "—" se assente)
- Format: `<comando>`
- Build: `<comando>`
- Run dev: `<comando>`
- Deploy: `<comando o note>`

## File di config notevoli
- `<path>` — <a cosa serve>

## Entry point
- App: `<file:line>` (es. `src/main.py:10 — uvicorn.run(app)`)
- CLI: `<se presente>`

## Test approach
- Framework: <pytest/jest/...>
- Pattern: <fixtures globali? mock layer? snapshot?>
- Esempio rilevante: `tests/<file>:<line>` — <cosa testa>

## Gotcha / quirk
- <pattern non ovvio scoperto durante la mappatura>
- <es. "il modulo X richiede env var Y settata anche per i test">
- <"—" se nessuno emerso>

## Riferimenti interni
- README: <linea chiave o "—">
- CONTRIBUTING: <linea chiave o "—">
- ARCHITECTURE/DESIGN doc: <path o "—">

## Note
- Aree non esplorate / da approfondire al prossimo passaggio
```

### 5. Output utente

```
**Codebase appreso: <slug>**

Stack: <linguaggio + framework principali>
Snapshot scritto in: `~/.claude/state/projects/<slug>/PATTERNS.md`

Highlight:
- <pattern interessante 1>
- <pattern interessante 2>
- <gotcha emerso>

Prossimo passo suggerito: `workflow-plan` (se hai un task in mente) o procedi a lavorare — `session-resume` lo rileggerà alla prossima sessione.
```

## Artefatti

- **Scrive**: `PATTERNS.md` (overwrite consapevole)
- **Legge**: file di config del repo per detection; usa `code-explorer` per la mappatura

## Subagent

- `code-explorer` per la mappatura — preserva il main context su un task naturalmente verboso.

## Cosa NON fai

- Niente modifiche al codice del progetto.
- Niente analisi di qualità/security/perf — quelle hanno skill/agent dedicati.
- Niente "best practices" generiche — solo cosa il progetto **fa** effettivamente, non cosa "dovrebbe".

## Note

- PATTERNS.md è uno **snapshot** datato. Se invecchia, va rifatto. Niente merge magico.
- Se il progetto è polyglot (es. Python backend + React frontend), elenca entrambi gli stack, distingui le sezioni per sub-area.
- Se non trovi info per una sezione, scrivi `—` esplicito invece di omettere. L'assenza è informazione.
