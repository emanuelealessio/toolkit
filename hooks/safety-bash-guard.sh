#!/usr/bin/env bash
# safety-bash-guard.sh — PreToolUse hook for Bash matcher.
# Warns (does NOT block) when destructive or risky shell patterns are detected.
# Receives a JSON payload on stdin with tool_input.command; exits 0 either way.
#
# Why warn-only: the user wants visibility on risky commands without losing
# autonomy. Hard blocks belong in a separate stricter profile.
set -euo pipefail

PAYLOAD="$(cat)"

# Extract the command. Prefer jq, fallback to python. Tolerate malformed JSON
# (exit 0 silently — never block the tool call for a hook implementation bug).
if command -v jq >/dev/null 2>&1; then
  CMD="$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
else
  CMD="$(printf '%s' "$PAYLOAD" | python3 -c 'import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get("tool_input",{}).get("command",""))
except Exception:
    pass' 2>/dev/null || true)"
fi

[ -z "$CMD" ] && exit 0

warn() {
  # Print to stderr in yellow; Claude Code surfaces stderr to the model.
  printf '\033[0;33m[safety-guard]\033[0m %s\n' "$*" >&2
}

# Patterns (extended regex). Ordered by severity, first match wins.

# 1. git push --force / -f on protected branches
if printf '%s' "$CMD" | grep -Eq 'git[[:space:]]+push[[:space:]]+(.*[[:space:]])?(-f|--force|--force-with-lease)([[:space:]]|$)'; then
  if printf '%s' "$CMD" | grep -Eq '(^|[[:space:]])(main|master|production|prod|release)([[:space:]]|$|:)'; then
    warn "RISCHIO: 'git push --force' su branch protetto rilevato. Conferma con l'utente prima di eseguire."
  else
    warn "Attenzione: 'git push --force' può sovrascrivere lavoro upstream. Considera --force-with-lease."
  fi
  exit 0
fi

# 2. git reset --hard
if printf '%s' "$CMD" | grep -Eq 'git[[:space:]]+reset[[:space:]]+(.*[[:space:]])?--hard'; then
  warn "Attenzione: 'git reset --hard' scarta modifiche non committate. Verifica che non ci sia lavoro non salvato."
  exit 0
fi

# 3. git branch -D / --delete --force on protected branches
if printf '%s' "$CMD" | grep -Eq 'git[[:space:]]+branch[[:space:]]+(.*[[:space:]])?(-D|--delete[[:space:]]+--force)([[:space:]]|$)'; then
  if printf '%s' "$CMD" | grep -Eq '(^|[[:space:]])(main|master|production|prod|release)([[:space:]]|$)'; then
    warn "RISCHIO: cancellazione forzata di branch protetto. Conferma con l'utente."
  fi
  exit 0
fi

# 4. rm -rf on dangerous paths
if printf '%s' "$CMD" | grep -Eq 'rm[[:space:]]+-[a-zA-Z]*[rR][a-zA-Z]*[fF][a-zA-Z]*'; then
  # Look for risky targets
  if printf '%s' "$CMD" | grep -Eq '(rm[[:space:]]+-[rRfF]+[[:space:]]+/($|[[:space:]]))|rm[[:space:]]+-[rRfF]+[[:space:]]+/\*'; then
    warn "RISCHIO ESTREMO: 'rm -rf /' o equivalente. Conferma intent prima di eseguire."
  elif printf '%s' "$CMD" | grep -Eq 'rm[[:space:]]+-[rRfF]+[[:space:]]+(\$HOME|~|~/)'; then
    warn "RISCHIO: 'rm -rf' su HOME directory. Conferma intent."
  elif printf '%s' "$CMD" | grep -Eq 'rm[[:space:]]+-[rRfF]+[[:space:]]+.*\.git([[:space:]]|/|$)'; then
    warn "Attenzione: 'rm -rf' su directory .git distrugge la history del repo."
  fi
  exit 0
fi

# 5. git commit --no-verify
if printf '%s' "$CMD" | grep -Eq 'git[[:space:]]+commit[[:space:]]+(.*[[:space:]])?--no-verify'; then
  warn "Attenzione: '--no-verify' bypassa i pre-commit hook. Usalo solo se l'utente lo ha chiesto esplicitamente."
  exit 0
fi

# 6. sudo on system-altering ops (very narrow)
if printf '%s' "$CMD" | grep -Eq 'sudo[[:space:]]+(rm|dd|mkfs|chmod|chown)[[:space:]]'; then
  warn "Attenzione: comando privilegiato che modifica il filesystem. Conferma intent."
  exit 0
fi

exit 0
