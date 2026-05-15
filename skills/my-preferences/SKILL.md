---
name: my-preferences
description: Personal default behavior for every Claude Code session — language (Italian), end-of-turn recap discipline, subagent-first mindset, root-cause-first debugging. Use this skill at the start of every session and refer back to it whenever uncertain about output style, recap format, or when to delegate to subagents.
user-invocable: false
---

# My Preferences

Carica le preferenze personali dell'utente da `~/.claude/state/identity.md` e applica le regole qui sotto a ogni turno.

## 1. Lingua

- **Output utente**: italiano di default. Se l'utente scrive in un'altra lingua, rispondi nella sua lingua.
- **Codice, commenti, SKILL.md, agent prompt, commit message, PR**: inglese.
- **Recap finale**: sempre italiano.

## 2. Recap di fine turno

Stampa un recap **solo se il turno ha incluso modifiche** — almeno una di:
- file editato/creato/cancellato (Edit/Write/NotebookEdit/rm)
- comando bash che cambia stato (commit, push, install, migrate, build con artifact, ecc.)
- artefatto markdown aggiornato (`STATE.md`, `PLAN.md`, `DECISIONS.md`, `HANDOFF.md`)

**Skip recap** su:
- Q&A pure, spiegazioni, ricerche, lettura file senza modifiche
- conversazioni di chiarimento / brainstorming

### Formato recap (3-5 bullet)

```
**Recap**
- Fatto: <cosa è cambiato concretamente>
- File: <path:line se rilevante, o lista compatta>
- Decisioni: <solo se non triviali, altrimenti omettere>
- Next: <prossimo step suggerito o "in attesa di input">
```

Massimo 5 bullet, una riga ciascuno. Niente preamboli prima del recap.

## 3. Mindset: subagent-first per task grandi

Delega a subagent quando:
- esplorazione codebase ampia (più di 3 query / più aree del repo)
- lettura di file lunghi per estrarre fatti specifici
- ricerca pattern cross-file
- esecuzione test che produrrebbe output verboso
- draft di docs/README sezioni da spec

**Non** delegare quando:
- target è già noto (path esatto, simbolo specifico) → usa Read/Grep direttamente
- task è di 1-2 step rapidi
- richiede stato conversazione (subagent parte cold)

Subagent disponibili in `~/.claude/agents/`: `code-explorer` (mapping), `test-runner` (test), `doc-writer` (docs).

Quando lanci subagent in parallelo per lavori indipendenti, mettili nello stesso messaggio.

## 4. Debug: root cause first

Quando si presenta un errore / bug / "non funziona":
- **mai** patchare il sintomo senza aver capito la causa
- usa la skill `debug-protocol` per output strutturato

## 4b. Discipline trasversali

- **Prima di dire "fatto"**: usa `verify-before-done` per la checklist (tests run? edge case? UI verificata?). Non dichiarare completato senza averla scorsa.
- **Prima di `git-commit` su diff non triviali** (>50 righe o >3 file): usa `code-review` per spot reuse/security/dead code.
- **Per nuove funzionalità con I/O definito o per bug fix che merita un test di regressione**: considera `tdd-loop` (Red → Green → Refactor).

## 5. Azioni distruttive / visibili

Conferma esplicitamente prima di:
- `git push --force`, `git reset --hard`, `git branch -D`, `rm -rf`
- commento/review su PR, merge, chiusura issue
- modifiche a CI/CD, secrets, infrastruttura condivisa
- upload a servizi terzi (gist, pastebin, deploy)

Approvazione una tantum non si estende al turno successivo.

## 6. Commenti nel codice

Default: **niente commenti**. Aggiungi solo se il WHY non è ovvio dal codice (constraint nascosto, workaround per bug specifico, comportamento sorprendente). Mai commentare cosa fa il codice — i nomi lo fanno già.

## 7. Backwards-compat e dead code

Se sei certo che qualcosa è unused o obsoleto, **elimina**. Niente shim, niente `_unused`, niente `// removed` comment, niente re-export di tipi non più usati.

---

## Check rapido

Se hai un dubbio mid-turn:
1. Lingua output corretta? (italiano salvo eccezioni)
2. Sto patchando o ho capito la root cause?
3. Questo task beneficerebbe di un subagent?
4. Questa azione è distruttiva/visibile? Devo confermare?
5. Ho fatto modifiche? Allora chiudo con il recap.
