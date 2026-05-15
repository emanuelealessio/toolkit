#!/usr/bin/env bash
# precompact-handoff.sh — PreCompact hook.
# Writes a minimal HANDOFF.md snapshot for the current project before the
# context window is compacted. Pure shell — no LLM. Safe to run silently.
#
# The HANDOFF.md it writes is intentionally minimal (git state only).
# For a full narrative handoff, the user should run the session-handoff skill
# manually before stopping. This hook is a safety net for forgotten handoffs.
set -euo pipefail

# Identify project slug from CWD (best effort; PreCompact runs at session level)
slug=""
if command -v git >/dev/null 2>&1; then
  slug="$(git remote get-url origin 2>/dev/null | sed 's|.*/||;s|\.git$||' || true)"
  if [ -z "$slug" ]; then
    slug="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")"
  fi
fi
[ -z "$slug" ] && slug="$(basename "$(pwd)")"

state_dir="${CLAUDE_HOME:-$HOME/.claude}/state/projects/$slug"

# Only write if state dir already exists — don't auto-bootstrap from a hook.
[ -d "$state_dir" ] || exit 0

timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
branch="$(git branch --show-current 2>/dev/null || echo 'n/a')"
last_commit="$(git log -1 --oneline 2>/dev/null || echo 'n/a')"
status_short="$(git status -s 2>/dev/null | head -20 || true)"
status_count="$(git status -s 2>/dev/null | wc -l | tr -d ' ' || echo 0)"

handoff="$state_dir/HANDOFF.md"

cat > "$handoff" <<EOF
# Handoff: $slug

> Saved: $timestamp · Auto (PreCompact hook) · Branch: $branch

## Task corrente
[Auto-snapshot — il contesto è stato compattato. Per un handoff narrativo completo,
esegui la skill \`session-handoff\` nella prossima sessione attiva.]

## Stato git
- Branch: $branch
- Last commit: $last_commit
- Modifiche non committate: $status_count file

\`\`\`
$status_short
\`\`\`

## Prossimi step
[Da ricostruire con \`session-resume\` + lettura PLAN.md / STATE.md]

## Note
Questo handoff è stato generato automaticamente dall'hook PreCompact perché
la context window stava per essere compressa. Sostituiscilo con un handoff
narrativo manuale quando riprendi la sessione.
EOF

exit 0
