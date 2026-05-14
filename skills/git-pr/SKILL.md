---
name: git-pr
description: Draft pull request title, body, and test plan in DRAFT MODE — show the draft and stop. Does not auto-push, does not auto-create. The user manually runs `gh pr create` (or via mcp__github__create_pull_request) when ready. Use when the user says "PR", "fai una PR", "draft una PR".
---

# Git PR (draft mode)

Prepara title, body e test plan per una PR. **Si ferma prima di pushare e prima di creare**. L'utente decide se procedere.

## Trigger

- L'utente dice "PR", "fai una PR", "apri una PR", "draft della PR".
- Branch ready (commits fatti, idealmente già pushato — ma se non lo è, lo segnali).

## Procedura

### 1. Raccogli contesto

In parallelo:
```bash
git status -s
git branch --show-current
git log <base-branch>..HEAD --oneline
git diff <base-branch>...HEAD --stat
```

Detect base branch: in ordine, `main`, `master`, `develop`. Se non chiaro, chiedi.

Leggi:
- `~/.claude/state/projects/<slug>/STATE.md` — task corrente
- `~/.claude/state/projects/<slug>/DECISIONS.md` — ultime decisioni per il body

### 2. Analizza **tutti** i commit del branch, non solo l'ultimo

Il PR copre l'intera divergenza dal base branch, non l'ultimo commit. Riassumi cumulativamente.

### 3. Drafta

Title:
- Max 70 char
- Imperativo presente
- Se i commit usano conventional commits, usa lo stesso style nel title (es. `feat(api): add user pagination`)
- Niente period finale

Body (template):

```markdown
## Summary
- <bullet 1: cosa è cambiato a livello utente/API/comportamento>
- <bullet 2: motivazione principale>
- <bullet 3: eventuali trade-off o note>

## Changes
- `path/to/file.py` — <una riga: cosa è cambiato>
- `path/to/other.py` — <una riga>
- ...

## Test plan
- [ ] <test concreto: comando o azione>
- [ ] <test concreto>
- [ ] <test concreto>

## Notes
<opzionale: breaking changes, follow-up, link a issue, screenshot per UI>
```

Test plan: bullet **eseguibili**, non vaghi. "Run pytest" non basta — "Run `pytest tests/api/test_users.py::test_pagination` and verify N items returned".

### 4. Mostra il draft all'utente

In chat:

```
**PR Draft**

Title: `<title>`

Base: `<base-branch>` ← Head: `<branch>` (N commits, M file)

Body:
<intero body markdown>

**Stato branch:**
- Commits ahead: N
- Pushato su origin: <sì/no>
- Modifiche non committate: <count, o "nessuna">

**Per creare la PR:**
\`\`\`bash
git push -u origin <branch>     # se non già pushato
gh pr create --title "<title>" --body "$(cat <<'EOF'
<body>
EOF
)"
\`\`\`

Oppure usa il tool MCP `mcp__github__create_pull_request` se disponibile.
```

### 5. STOP

**Non** eseguire `git push`, **non** eseguire `gh pr create`, **non** chiamare `mcp__github__create_pull_request`. L'utente decide e lancia.

Eccezione: se l'utente dice esplicitamente "creala anche" o "push e PR", allora procedi — ma chiedi conferma del title/body prima.

## Artefatti

- **Legge**: `STATE.md`, `DECISIONS.md`, log/diff git
- **Scrive**: niente

## Regole hard

- Mai push automatico su `main` o `master`.
- Mai force-push.
- Se ci sono modifiche non committate, segnalalo: l'utente probabilmente vuole prima `git-commit`.
- Title in inglese (salvo repo italiano).
