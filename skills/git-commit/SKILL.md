---
name: git-commit
description: Draft a conventional-commit message and create a NEW commit (never amend unless explicitly asked, never use `git add -A`). Use when the user says "commit", "fai un commit", or staging is ready and they want a message. Reads recent DECISIONS.md for context on non-trivial changes.
---

# Git Commit

Drafta un messaggio commit coerente con il repo e crea un **nuovo** commit. Mai amend, mai `-A`.

## Trigger

- L'utente dice "commit", "fai un commit", "committa".
- Modifiche pronte (staged o lavoro completato che vuole essere committato).

## Procedura

### 1. Check pre-commit

In parallelo (un solo messaggio bash):
```bash
git status -s
git diff --cached --stat            # cosa è staged
git diff --stat                     # cosa NON è staged
git log -5 --oneline                # style dei messaggi recenti
```

### 2. Decidi cosa staggare

- Se l'utente non l'ha già fatto, mostragli cosa è modificato e **chiedi quali file staggare**, salvo che sia ovvio (es. un solo file toccato che è chiaramente l'oggetto del lavoro).
- **Mai** `git add -A` o `git add .`. Adda file specifici per nome.
- **Mai** committare file sospetti (`.env`, `credentials.*`, `*.pem`, `*.key`, binari grandi). Se l'utente li include esplicitamente, conferma due volte.

### 3. Drafta il messaggio

Style: **Conventional Commits** se il repo li usa già (controlla `git log`). Altrimenti adatta allo style esistente.

Formato base:
```
<type>(<scope opzionale>): <subject, max 72 char, imperativo presente, no punto finale>

<body opzionale, wrappato a ~72 char, spiega il PERCHÉ non il COSA>

<footer opzionale: BREAKING CHANGE, refs #issue>
```

`type` comuni: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `build`, `ci`, `style`.

Body in **inglese**. Italiano solo se l'utente lo richiede o se il repo è già italiano.

Se la modifica è significativa, leggi `~/.claude/state/projects/<slug>/DECISIONS.md` (ultime sezioni) per arricchire il body con il WHY.

### 4. Mostra all'utente prima di committare

```
**Commit message proposto:**
<type>(<scope>): <subject>

<body>

File da committare:
- path/to/file1
- path/to/file2

Procedo?
```

Attendi conferma.

### 5. Esegui il commit

Usa HEREDOC per preservare formattazione:

```bash
git add path/to/file1 path/to/file2
git commit -m "$(cat <<'EOF'
<type>(<scope>): <subject>

<body>
EOF
)"
```

### 6. Verifica

```bash
git status
git log -1 --stat
```

## Regole hard

- **Mai** `--amend` senza richiesta esplicita dell'utente.
- **Mai** `--no-verify` o `--no-gpg-sign` salvo richiesta esplicita.
- **Mai** `git add -A` / `git add .` / `git add -i`.
- Se un pre-commit hook fallisce: il commit **non è avvenuto**. Risolvi il problema, ri-stagga, **nuovo** commit. Non amendare il commit precedente.
- Niente firma "Co-authored-by" o trailers automatici a meno che il repo abbia convention specifica.

## Artefatti

- **Legge**: `DECISIONS.md` recenti
- **Scrive**: niente (il commit stesso è l'artefatto)

## Note

- Se il diff è enorme (>500 righe) o eterogeneo (più feature in uno), **suggerisci di splittarlo** in più commit logici prima di committare.
- Subject in inglese imperativo: "add X" non "added X" né "adds X".
