---
name: code-review
description: Self-review of staged or in-progress changes — spot reuse opportunities, simplicity wins, security issues, dead code. Use before `git-commit` or when user says "review", "rivedi", "guarda se va bene il codice". Complements (not replaces) `verify-before-done` which is about runtime behavior.
allowed-tools: Read, Grep, Glob, Bash(git status:*), Bash(git diff:*), Bash(git log:*)
---

# Code Review (self)

Review delle modifiche prima del commit. Focus: riuso, semplicità, security, dead code. **Non** verifica runtime — quella è `verify-before-done`.

## Quando usarla

- Prima di `git-commit`, soprattutto se il diff è non triviale (>50 righe o >3 file).
- L'utente dice "review", "rivedi il codice", "guarda se va bene", "controlla il diff".
- Auto-trigger consigliato dentro `workflow-execute` dopo step grossi.

## Procedura

### 1. Leggi il diff completo

```bash
git diff --cached      # staged
git diff               # unstaged
git diff --stat        # overview
```

Non revieware "a memoria" — leggi il diff vero.

### 2. Per ogni hunk passa la checklist

**Riuso (prima di tutto):**
- Esiste già funzione/util che fa la stessa cosa? Grep per nomi/pattern simili.
- Sto duplicando logica esistente? Se sì, riusa o estrai.

**Semplicità:**
- Si può fare con meno righe senza perdere chiarezza?
- C'è un'astrazione prematura (interfaccia con un solo impl, factory inutile, wrapper ridondante)?
- 3 righe simili ripetute sono OK; 7+ vale un'estrazione.

**Sicurezza (per ciò che attraversa boundary):**
- Input utente validato? SQL/shell/path injection?
- Secrets/credenziali in codice o log?
- Permissions check su operazioni privilegiate?

**Error handling:**
- Try/catch che ingoia eccezioni senza loggare? Rimuovi o logga.
- Validazione su confini (input utente, API esterne) sì; su codice interno no, lascia che fallisca pulito.
- Fallback per condizioni che non possono accadere → rimuovi.

**Dead code & noise:**
- Import non usati, variabili non lette, funzioni non chiamate, branch irraggiungibili.
- `console.log` / `print` di debug.
- Codice commentato (cancellalo, git ha la history).
- Backwards-compat shim per cose mai rilasciate.

**Commenti:**
- Commenti che spiegano *cosa* fa il codice → cancellare, il nome lo fa già.
- Commenti che riferiscono task/issue ("added for PR #123") → cancellare, appartengono alla PR description.
- Commenti che spiegano *perché* (constraint nascosto, workaround per bug noto) → tenere.

**Naming:**
- Variabili `data`, `tmp`, `result` quando si può essere più specifici → rinomina.
- Funzioni che fanno N cose → split.

### 3. Output

Lista compatta dei problemi trovati. Una riga per problema, con file:line + suggerimento. Esempio:

```
**Review:**
- `src/api.py:42` — duplica `format_user()` (src/utils.py:17), riusa
- `src/api.py:88-95` — try/catch ingoia errore, almeno logga
- `src/api.py:120` — commento "added for issue 42" → rimuovi
- `tests/test_api.py:5` — import `pytest_asyncio` non usato
- `src/utils.py:30` — funzione `_helper()` non chiamata da nessuno → rimuovi

Suggerimenti applicati? L'utente decide quali fixare prima di committare.
```

Se tutto pulito:
```
**Review: clean.** Nessun problema rilevante. Pronto per commit.
```

### 4. STOP

Non applicare i fix automaticamente — l'utente decide. Se l'utente dice "fixa tutto", procedi con Edit.

## Anti-pattern

- Revieware riassumendo a memoria invece di leggere il diff.
- Commentare in chat *cosa* fa il codice ("questa funzione fa X") — sposta sul codice se serve, ma in genere il nome basta.
- Aggiungere refactor extra in review ("ho anche pulito Y") — il review propone, non esegue. Estensione fuori scope.
- Dare lista di 30 nitpick — filtra ai 5 più rilevanti, il resto è rumore.

## Subagent

- `code-explorer` se il diff tocca aree larghe e devi capire riuso esistente.

## Note

- Per diff piccolo (<20 righe, 1 file), una review veloce in chat basta — non serve checklist completa.
- Se il diff è ENORME (>500 righe), suggerisci di splittare in commit logici prima della review.
- Mai pushare in repo terzi un review automatico — `code-review` è skill personale, su tue branch.
