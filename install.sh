#!/usr/bin/env bash
# Install the personal Claude Code toolkit into ~/.claude/.
# Idempotent: re-running is a no-op. Symlink-based so `git pull` propagates instantly.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
SKILLS_DIR="$CLAUDE_HOME/skills"
AGENTS_DIR="$CLAUDE_HOME/agents"
STATE_DIR="$CLAUDE_HOME/state"
BACKUPS_DIR="$CLAUDE_HOME/backups"
SETTINGS="$CLAUDE_HOME/settings.json"
FRAGMENT="$REPO/settings/settings.fragment.json"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { printf "${GREEN}[install]${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}[install]${NC} %s\n" "$*"; }
fail()  { printf "${RED}[install]${NC} %s\n" "$*" >&2; exit 1; }

preflight() {
  case "$(uname -s)" in
    Linux|Darwin) ;;
    *) fail "OS non supportato: $(uname -s). Usa WSL su Windows." ;;
  esac
  command -v python3 >/dev/null || fail "python3 mancante"
  command -v git     >/dev/null || fail "git mancante"
}

backup_once() {
  if [ ! -d "$BACKUPS_DIR" ] || ! ls "$BACKUPS_DIR"/pre-toolkit-* >/dev/null 2>&1; then
    mkdir -p "$BACKUPS_DIR"
    local ts="pre-toolkit-$(date +%s)"
    if [ -d "$CLAUDE_HOME" ]; then
      # Backup only file artifacts, not the whole tree (avoids recursive copy of backups/).
      mkdir -p "$BACKUPS_DIR/$ts"
      [ -f "$SETTINGS" ] && cp -a "$SETTINGS" "$BACKUPS_DIR/$ts/settings.json" || true
      info "backup creato: $BACKUPS_DIR/$ts"
    fi
  fi
}

link_dir() {
  # link_dir <src> <dst>: create symlink, abort if dst exists and is not our link.
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    local current
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then return 0; fi
    fail "symlink esistente con target diverso: $dst -> $current (atteso: $src)"
  elif [ -e "$dst" ]; then
    fail "conflitto: $dst esiste e non è un symlink. Rimuovilo o spostalo prima di installare."
  fi
  ln -s "$src" "$dst"
  info "linkato: $dst -> $src"
}

install_skills() {
  mkdir -p "$SKILLS_DIR"
  for d in "$REPO"/skills/*/; do
    [ -d "$d" ] || continue
    local name
    name="$(basename "$d")"
    link_dir "$REPO/skills/$name" "$SKILLS_DIR/$name"
  done
}

install_agents() {
  mkdir -p "$AGENTS_DIR"
  for f in "$REPO"/agents/*.md; do
    [ -f "$f" ] || continue
    local name
    name="$(basename "$f")"
    link_dir "$REPO/agents/$name" "$AGENTS_DIR/$name"
  done
}

merge_settings() {
  mkdir -p "$CLAUDE_HOME"
  if [ ! -f "$FRAGMENT" ]; then
    warn "fragment $FRAGMENT non trovato, skip merge"
    return 0
  fi
  python3 "$REPO/lib/merge-settings.py" "$FRAGMENT" "$SETTINGS"
  info "settings.json fuso"
}

scaffold_state() {
  mkdir -p "$STATE_DIR/projects"
  if [ ! -f "$STATE_DIR/identity.md" ]; then
    if [ -f "$REPO/templates/identity.md" ]; then
      cp "$REPO/templates/identity.md" "$STATE_DIR/identity.md"
      info "identity.md creato da template"
    fi
  fi
}

verify() {
  local errors=0
  printf "\n--- Verify ---\n"
  for d in "$REPO"/skills/*/; do
    local name dst
    name="$(basename "$d")"
    dst="$SKILLS_DIR/$name"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$REPO/skills/$name" ]; then
      printf "  ${GREEN}OK${NC}  skill $name\n"
    else
      printf "  ${RED}KO${NC}  skill $name\n"; errors=$((errors+1))
    fi
  done
  for f in "$REPO"/agents/*.md; do
    [ -f "$f" ] || continue
    local name dst
    name="$(basename "$f")"
    dst="$AGENTS_DIR/$name"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$REPO/agents/$name" ]; then
      printf "  ${GREEN}OK${NC}  agent $name\n"
    else
      printf "  ${RED}KO${NC}  agent $name\n"; errors=$((errors+1))
    fi
  done
  if python3 -c "import json,sys; json.load(open('$SETTINGS'))" 2>/dev/null; then
    printf "  ${GREEN}OK${NC}  settings.json parsabile\n"
  else
    printf "  ${RED}KO${NC}  settings.json non parsabile\n"; errors=$((errors+1))
  fi
  [ -d "$STATE_DIR" ] && printf "  ${GREEN}OK${NC}  state dir\n" || { printf "  ${RED}KO${NC}  state dir mancante\n"; errors=$((errors+1)); }
  [ -f "$STATE_DIR/identity.md" ] && printf "  ${GREEN}OK${NC}  identity.md\n" || printf "  ${YELLOW}--${NC}  identity.md non presente (template assente?)\n"
  printf "\n"
  [ $errors -eq 0 ] || fail "$errors verifiche fallite"
  info "tutto verde"
}

main() {
  if [ "${1:-}" = "--verify" ]; then
    verify
    return 0
  fi
  preflight
  backup_once
  install_skills
  install_agents
  merge_settings
  scaffold_state
  verify
  info "install completato"
}

main "$@"
