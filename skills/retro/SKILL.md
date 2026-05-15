---
name: retro
description: Capture a lesson learned from the work just done and append it to LESSONS.md (per-project, append-only). Use at the end of a non-trivial task, when the user says "lesson learned", "ho imparato che", "retro", or when verify-before-done suggests it. Different from DECISIONS.md (which logs architectural choices); this captures generalizable lessons — what to do/not do next time on this project.
disable-model-invocation: true
allowed-tools: Read, Write, Bash(git status:*), Bash(git log:*), Bash(git remote get-url:*), Bash(git rev-parse:*)
---

# Retro

Cattura una lesson learned dal lavoro appena fatto e appendila a `LESSONS.md` per-progetto. **Loop di apprendimento runtime**: complemento a `learn-codebase` (cattura strutturale). Entrambi vengono riletti da `session-resume`.

## Quando usarla

- Fine di un task non triviale (bug fix non ovvio, refactor che ha richiesto iterazioni, integrazione nuova).
- L'utente dice "lesson learned", "ho imparato che", "retro", "annota".
- `verify-before-done` ha segnalato un finding interessante (edge case mancato, regressione vicina, gotcha).
- Hai rifatto due volte lo stesso errore in sessioni diverse — quello è il signal.

**Non** serve per: ogni edit, fix di typo, lavoro di routine ben mappato.

## Procedura

### 1. Risolvi slug e state dir

```bash
slug=$(git remote get-url origin 2>/dev/null | sed 's|.*/||;s|\.git$||')
[ -z "$slug" ] && slug=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
state_dir="$HOME/.claude/state/projects/$slug"
mkdir -p "$state_dir"
```

### 2. Distilla la lesson

Una lesson utile è:
- **Generalizzabile** — vale per casi simili in futuro, non è specifica al singolo bug.
- **Azionabile** — descrive un'azione concreta da prendere o evitare, non un'osservazione astratta.
- **Riconoscibile** — il trigger ("quando vedi X") è chiaro al re-incontro.

Categorie tipiche:
- **Gotcha**: comportamento non ovvio del codebase/framework.
- **Workflow**: pattern di lavoro che ha funzionato/fallito su questo progetto.
- **Anti-pattern**: cosa NON fare qui (anche se è ok altrove).
- **Setup**: requisito non documentato che ti ha bloccato (env var, dep mancante, ordine di comandi).
- **Test**: pattern di test che si replica bene / falso amico (es. mock che nasconde un bug reale).

Se la "lesson" è solo "ho fatto X", **non scriverla**: non è generalizzabile, è solo storia. Quella sta in `STATE.md > History`.

### 3. Appendi a LESSONS.md

**Append-only**, mai overwrite. Sezione H2 datata. Formato:

```markdown
## 2026-05-15T16:42 — <titolo corto azionabile>

**Categoria**: gotcha | workflow | anti-pattern | setup | test

**Contesto**
<1-2 frasi: cosa stavo facendo quando è emerso>

**Lesson**
<2-4 frasi: il principio da ricordare. Imperativo presente. Es. "Prima di X, controlla Y" / "Mai usare Z su questo modulo perché W">

**Trigger di re-applicazione**
<come riconoscere quando questa lesson si applica di nuovo: "quando lavori su modulo X" / "quando vedi errore Y" / "ogni volta che modifichi Z">

**Riferimenti**
- `path/file.py:line` — esempio concreto
- Commit `<sha breve>` — fix originale (se applicabile)
```

Se `LESSONS.md` non esiste, crealo con un header:

```markdown
# Lessons: <slug>

Append-only log di pattern, gotcha, anti-pattern emersi lavorando su questo progetto.
Riletto da `session-resume` (ultime 3-5 voci). Sezioni datate, mai overwrite.

---
```

### 4. Output utente

Conciso, in italiano:

```
**Lesson registrata: <titolo>**
File: `~/.claude/state/projects/<slug>/LESSONS.md`
Trigger di re-applicazione: <una frase>
```

## Artefatti

- **Scrive**: `LESSONS.md` (append-only)
- **Legge**: contesto sessione, `git status/log` se serve per i riferimenti

## Cosa NON fai

- Mai overwrite di lesson esistenti. Se una è obsoleta, l'utente la cancella a mano.
- Niente "buoni consigli" generici tipo "scrivi test", "fai commit piccoli". Tutto deve essere **specifico** a questo progetto.
- Niente lesson auto-elogiative ("ho gestito bene X"). Le lesson utili sono quelle che evitano errori futuri, non quelle che celebrano il presente.
- Niente generalizzazioni precoci: se una cosa è successa una volta, è un caso. Servono 2+ occorrenze (o un'analisi che mostri che si ripeterà) per chiamarla pattern.

## Note

- `LESSONS.md` cresce: dopo 20-30 voci, l'utente potrebbe voler archiviare le più vecchie in `LESSONS-archive-<YYYY>.md`. Suggeriscilo se vedi che il file è enorme.
- Distinzione importante con `DECISIONS.md`:
  - `DECISIONS.md` = scelte architetturali fatte (es. "abbiamo scelto httpx vs aiohttp perché…").
  - `LESSONS.md` = lessons trasversali ricorrenti (es. "su questo repo i test async richiedono `@pytest.mark.asyncio(loop_scope='session')` o si rompono").
- `session-resume` legge le ultime 3-5 voci di `LESSONS.md`: questo è il loop che chiude il flywheel.
