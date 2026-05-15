#!/usr/bin/env bash
# Remove the toolkit's symlinks from ~/.claude/. Restore settings.json from most recent backup.
# Preserves ~/.claude/state/ (user data).
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
SKILLS_DIR="$CLAUDE_HOME/skills"
AGENTS_DIR="$CLAUDE_HOME/agents"
HOOKS_DIR="$CLAUDE_HOME/hooks"
BACKUPS_DIR="$CLAUDE_HOME/backups"
SETTINGS="$CLAUDE_HOME/settings.json"
EXTERNAL_DIR="$CLAUDE_HOME/external"
ANTHROPIC_DIR="$EXTERNAL_DIR/anthropics-skills"
PURGE_EXTERNAL=0

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'
info() { printf "${GREEN}[uninstall]${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}[uninstall]${NC} %s\n" "$*"; }

unlink_if_ours() {
  local dir="$1" prefix="$2"
  [ -d "$dir" ] || return 0
  for entry in "$dir"/*; do
    [ -L "$entry" ] || continue
    local target
    target="$(readlink "$entry")"
    case "$target" in
      "$REPO/$prefix/"*)
        rm "$entry"
        info "rimosso symlink: $entry"
        ;;
    esac
  done
}

unlink_anthropic() {
  [ -d "$SKILLS_DIR" ] || return 0
  for entry in "$SKILLS_DIR"/*; do
    [ -L "$entry" ] || continue
    local target
    target="$(readlink "$entry")"
    case "$target" in
      "$ANTHROPIC_DIR/"*)
        rm "$entry"
        info "rimosso symlink anthropic: $entry"
        ;;
    esac
  done
  if [ "$PURGE_EXTERNAL" = "1" ] && [ -d "$ANTHROPIC_DIR" ]; then
    rm -rf "$ANTHROPIC_DIR"
    info "rimosso clone $ANTHROPIC_DIR"
    # rmdir external/ only if empty
    rmdir "$EXTERNAL_DIR" 2>/dev/null || true
  fi
}

restore_settings() {
  local latest
  latest="$(ls -1dt "$BACKUPS_DIR"/pre-toolkit-* 2>/dev/null | head -n1 || true)"
  if [ -n "$latest" ] && [ -f "$latest/settings.json" ]; then
    cp "$latest/settings.json" "$SETTINGS"
    info "settings.json ripristinato da $latest"
  else
    warn "nessun backup settings.json trovato, file non toccato"
  fi
}

main() {
  for arg in "$@"; do
    case "$arg" in
      --purge-external) PURGE_EXTERNAL=1 ;;
    esac
  done
  unlink_if_ours "$SKILLS_DIR" "skills"
  unlink_if_ours "$AGENTS_DIR" "agents"
  unlink_if_ours "$HOOKS_DIR" "hooks"
  unlink_anthropic
  restore_settings
  info "uninstall completato (state preservato in $CLAUDE_HOME/state)"
}

main "$@"
