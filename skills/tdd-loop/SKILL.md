---
name: tdd-loop
description: Test-Driven Development discipline — Red → Green → Refactor. Use when adding new functionality with clear input/output behavior, when the user says "TDD", "test prima", "fai TDD", or when bug fix needs a regression test. Forces a failing test before any production code.
allowed-tools: Read, Edit, Write, Grep, Glob, Bash(pytest:*), Bash(npm test:*), Bash(npm run test:*), Bash(cargo test:*), Bash(go test:*), Bash(mix test:*), Bash(bundle exec rspec:*), Bash(git status:*), Bash(git diff:*)
---

# TDD Loop

Disciplina Red → Green → Refactor. Nessun codice di produzione senza un test rosso che lo giustifichi.

## Quando usarla

- Nuova funzionalità con comportamento I/O definibile (funzioni pure, endpoint API, parser, validator).
- Bug fix che merita un test di regressione.
- L'utente dice "TDD", "test prima", "fai TDD", "test driven".

**Non** forzare TDD per: prototipi esplorativi rapidi, refactor puro senza change di behavior, fix di typo/lint.

## Procedura

### 1. RED — scrivi un test che fallisce

- **Uno** test, mirato a un comportamento concreto.
- Esegui i test. Conferma che il nuovo test fallisce con il messaggio atteso. Se passa, è bug nel test, non nel codice.
- Output utente: nome test + comando + riga di failure.

### 2. GREEN — minimo codice per passare

- Il minimo. Non aggiungere quello che il test non richiede.
- Esegui i test. Tutti verdi.
- Se devi cambiare codice per far passare ALTRI test, fermati: il nuovo test si stava sovrapponendo a copertura esistente — riconsidera il design del test.

### 3. REFACTOR — pulisci

- Rinomina, estrai, deduplica, semplifica.
- I test devono restare verdi dopo ogni micro-step.
- Stop appena il codice è pulito. Non "abbellire" oltre.

### 4. Loop

Torna al passo 1 per il prossimo comportamento. Test → codice → pulizia. Mai due step di seguito senza nuovo test.

## Subagent

- `test-runner` per eseguire la suite senza pollare il main context con output verboso.

## Output utente per ciclo

Una riga compatta per ogni fase:

```
[RED] tests/test_foo.py::test_pagination — fail: expected 10, got 0
[GREEN] src/foo.py:42-58 — pagination loop
[REFACTOR] extract slice() into helper, all 23 tests verdi
```

## Anti-pattern

- Scrivere codice "preventivo" non coperto da test.
- Test che passano già al primo run (= bug nel test).
- Saltare il refactor "tanto poi sistemo".
- Scrivere 5 test, poi 5 implementazioni. Il loop è **uno per volta**.

## Note

- Se la suite è lenta, isola il test del momento (`pytest -k`, `npm test -- -t`, ecc.) durante il loop.
- Aggiorna `DECISIONS.md` solo se il design emerso dal TDD è non triviale.
