---
name: verify-before-done
description: Pre-completion verification checklist — prevents premature "done" claims. Use at the end of any implementation turn before reporting completion, especially before saying "fatto", "done", "implementato". Distilled from Superpowers (obra). One of the highest-impact disciplines.
allowed-tools: Read, Bash(git status:*), Bash(git diff:*), Bash(git log:*)
---

# Verify Before Done

Prima di dichiarare un task completato, percorri la checklist. Niente "fatto" anticipato.

## Quando usarla

- Hai appena finito una serie di edit e stai per chiudere il turno.
- Stai per scrivere "fatto", "done", "implementato", "pronto".
- Prima di `git-commit` o di un recap di chiusura.

## Checklist

Vai voce per voce. Se una fallisce, **non** dire fatto — risolvi o segnala esplicitamente.

### 1. Test
- Tests rilevanti runnati? Output letto, non assunto?
- Test rossi pre-esistenti documentati o erano stati verdi prima dei miei edit?
- Edge cases coperti (empty input, null, boundary, errors)?

### 2. Comportamento osservabile
- Per UI changes: aperto in browser/dev server, visto coi miei occhi? Se no, **dirlo**.
- Per API/CLI: lanciato con input reale, output verificato?
- Per migration/script: dry-run prima?

### 3. Regressioni
- Le aree che ho toccato non rompono altro? Test correlati passano?
- Nessuna feature collaterale ho cambiato senza accorgermene (`git diff` letto)?

### 4. Pulizia
- `console.log`/`print` di debug rimossi?
- Import inutilizzati rimossi?
- Codice morto eliminato (non commentato)?
- File temporanei (`.bak`, `tmp_*.py`) cancellati?

### 5. Stato git
- Modifiche staged sono quelle che pensavo (`git diff --cached`)?
- File sensibili (`.env`, secrets) NON staged?
- Branch giusto?

### 6. Documentazione
- README/docstring aggiornati se l'API è cambiata?
- `DECISIONS.md` aggiornato se decisione architetturale non triviale?

## Output

Se tutto verde:
```
**Verificato:**
- ✓ tests (N/N verdi)
- ✓ behavior (descrivi come testato)
- ✓ no regression
- ✓ pulizia
```

Se qualcosa **non** è stato verificato (es. UI in CLI environment):
```
**Stato:**
- ✓ tests (12/12)
- ✓ code review self
- ⚠ UI non verificata in browser (CLI environment) — controlla tu
- ✗ edge case X non testato — TODO
```

Onestà > apparenza di completezza.

### 7. Lesson learned (opzionale, solo se task non triviale)
- È emerso un gotcha non documentato, un anti-pattern di questo progetto, un requisito di setup nascosto?
- Se sì: dopo aver chiuso, suggerisci all'utente di lanciare `retro` per appenderlo a `LESSONS.md`. Una sola lesson per task — niente spam.
- Se no: skip silenziosamente, niente "non c'era nulla da imparare" performativo.

## Anti-pattern

- "Dovrebbe funzionare" senza averlo runnato.
- "Type checking passa quindi funziona" — type check verifica correttezza, non comportamento.
- "Il test che ho scritto passa" senza considerare il resto della suite.
- "Fatto" + push immediato senza una rilettura del diff.

## Note

- Per task UI, se non puoi testare in browser, **dichiaralo esplicitamente** invece di dire "fatto".
- Se il turno è stato lungo, il rischio di skip cresce: la checklist è ancora più importante.
