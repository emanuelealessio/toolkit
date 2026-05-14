---
name: project-bootstrap
description: Initialize a new project's state in ~/.claude/state/projects/<slug>/ by detecting language/stack and seeding PROJECT.md and STATE.md from templates. Use on empty or near-empty repos, when the user says "nuovo progetto", "setup", "bootstrap", or when other workflow skills find no per-project state.
---

# Project Bootstrap

Crea lo stato iniziale per un progetto in `~/.claude/state/projects/<slug>/`, rilevando stack e seedando i template.

## Trigger

- L'utente dice "nuovo progetto", "setup", "bootstrap", "init il toolkit qui".
- Una skill workflow (`workflow-plan`, `session-resume`) trova `<state_dir>` mancante e suggerisce bootstrap.
- Repo appena clonato/inizializzato.

## Procedura

### 1. Risolvi slug

```bash
slug=$(git remote get-url origin 2>/dev/null | sed 's|.*/||;s|\.git$||')
[ -z "$slug" ] && slug=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
state_dir="$HOME/.claude/state/projects/$slug"
```

Se `state_dir` esiste già con artefatti:
> `state_dir` esiste già per `<slug>`. Vuoi sovrascrivere (perdi history), aggiornare solo PROJECT.md, o annullare?

### 2. Detect stack

Controlla in parallelo:

```bash
ls -1 package.json pyproject.toml requirements.txt Cargo.toml go.mod mix.exs Gemfile composer.json Dockerfile 2>/dev/null
```

Rileva:
- **Python**: `pyproject.toml`, `requirements.txt`, `setup.py`
- **Node**: `package.json` (controlla `pnpm-lock.yaml`/`yarn.lock` per package manager)
- **Rust**: `Cargo.toml`
- **Go**: `go.mod`
- **Elixir**: `mix.exs`
- **Ruby**: `Gemfile`
- **PHP**: `composer.json`
- **Containerized**: presenza `Dockerfile` o `docker-compose.yml`

Estrai dettagli mirati: linguaggio, framework principale (FastAPI / Next.js / Rails / etc. — grep dep), test runner.

### 3. Crea state_dir e seed

```bash
mkdir -p "$state_dir"
```

Copia da template (in `~/toolkit/templates/`):

- `PROJECT.md` → `$state_dir/PROJECT.md`, riempiendo:
  - `<slug>`, timestamp ISO, `<URL>` da `git remote get-url origin`
  - Stack rilevato
  - Branch convenzioni (controlla `.github/CONTRIBUTING.md` se presente)
  - Commit style (controlla `git log -20 --oneline` per pattern)
- `STATE.md` → `$state_dir/STATE.md`, riempiendo `Now > Branch` e `Ultima sessione`

**Non** creare `PLAN.md`, `DECISIONS.md`, `HANDOFF.md` qui — verranno creati on-demand dalle altre skill.

### 4. Eventuale seed nel repo

Solo se l'utente lo chiede esplicitamente o se il repo è vuoto:
- Suggerisci `.gitignore` minimo per il linguaggio detectato
- Suggerisci `README.md` minimale (delega a `doc-writer` se vuole un draft serio)

**Non** committare nulla — solo proposte.

### 5. Output

```
**Bootstrap completato: <slug>**

Stack rilevato: <linguaggio> / <framework principale> / <test runner>

State creato in: `~/.claude/state/projects/<slug>/`
- PROJECT.md  (rivedi e correggi placeholder)
- STATE.md

Suggerimenti opzionali:
- <es. .gitignore Python> — vuoi che lo crei?
- <es. README iniziale> — uso doc-writer?

Prossimo step: `workflow-plan` per pianificare la prima feature, oppure inizia a lavorare e usa `session-handoff` quando ti fermi.
```

## Artefatti

- **Scrive**: `PROJECT.md`, `STATE.md` in `~/.claude/state/projects/<slug>/`
- **Legge**: file di config del repo per detection

## Note

- Mai sovrascrivere artefatti esistenti senza conferma.
- Se il progetto non è un repo git (no `.git`), va bene lo stesso: lo slug viene dal basename del cwd.
- Per progetti polyglot (es. Python backend + Node frontend), elencali entrambi in `PROJECT.md > Stack`.
