---
name: debug-protocol
description: Structured debugging output for bugs, errors, stack traces, or unexpected behavior. Enforces the format Symptom → Root cause → Fix → Why this approach. Use whenever the user reports a bug or an error appears, instead of patching symptoms. Logs non-trivial fixes to DECISIONS.md.
allowed-tools: Read, Grep, Glob, Edit, Write
---

# Debug Protocol

Quando si presenta un bug, errore, o comportamento non atteso, **non patchare il sintomo**. Segui il protocollo a 4 blocchi.

## Trigger

- L'utente segnala un bug, un test rosso, un'eccezione.
- Compare uno stack trace o un errore in output.
- L'utente dice "non funziona", "perché fa X invece di Y", "debug".

## Procedura

### 1. Identifica root cause

Prima di toccare codice:

- Riproduci il problema (caso minimo). Se non riproducibile, è un blocker — chiedi all'utente più info.
- Forma un'**ipotesi** sulla causa. Scrivila esplicitamente.
- Verifica l'ipotesi: leggi i file rilevanti, inspect state, test mirato. Delega a `code-explorer` se l'area è larga.
- Se l'ipotesi era sbagliata, ripeti. Niente shortcut.

Tecniche utili:
- **5 whys**: ogni "perché?" affonda di un livello.
- **Bisect**: per regressioni, `git bisect` o checkout di commit intermedi.
- **Isolate**: rimuovi pezzi finché il bug sparisce, l'ultimo pezzo rimosso è la causa.

### 2. Progetta il fix

- Il fix deve attaccare la **causa**, non il sintomo.
- Considera almeno un'alternativa. Scegli con criterio chiaro (semplicità, copertura test, impatto perimetrale).
- Se il fix è ampio (>30 righe o tocca >2 file) → considera se serve `workflow-plan` prima di implementare.

### 3. Implementa e verifica

- Applica il fix.
- Esegui test (delega a `test-runner` se output verboso).
- Verifica che il sintomo originale sia sparito **e** che non si siano introdotte regressioni.

### 4. Output strutturato

In chat all'utente, formato a 4 blocchi:

```
**Symptom**
<descrizione concreta del problema osservato, con stack trace/comportamento se rilevante>

**Root cause**
<la causa effettiva, non il sintomo. Cita file:line se applicabile>

**Fix**
<cosa hai cambiato. Lista file modificati con path:line>

**Why this approach**
<perché questo fix invece di alternative. 1-2 frasi. Eventuali trade-off.>
```

### 5. Log in DECISIONS.md (se non triviale)

Se il bug era non ovvio, il fix non triviale, o il root cause è una decisione architetturale da ricordare → appendi a `~/.claude/state/projects/<slug>/DECISIONS.md`:

```markdown
## 2026-05-14T16:00 — Bug fix: <descrizione corta>
- Sintomo: <riga>
- Root cause: <riga>
- Fix: <file:line + 1 riga descrizione>
- Note: <opzionale, gotcha futuri>
```

Slug detection come nelle altre skill workflow.

## Cosa evitare

- Try/catch che ingoia l'errore senza capire perché succede.
- Random "spegni e riaccendi" — restart, clear cache, reinstall — senza diagnosi.
- Fix che funziona ma non sai perché. Se non sai perché, **continua a investigare**.
- Aggiungere log/print "tanto per vedere" senza un'ipotesi precisa.

## Artefatti

- **Scrive**: `DECISIONS.md` (append, solo se fix non triviale)
- **Legge**: contesto del progetto se serve

## Subagent

- `code-explorer` per investigare aree larghe del codebase.
- `test-runner` per verificare il fix senza output verboso in main context.
