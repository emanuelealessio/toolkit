#!/usr/bin/env bats
# install.bats — install/uninstall integration tests using an isolated CLAUDE_HOME.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  TMP_HOME="$(mktemp -d -t toolkit-test-XXXXXX)"
  export CLAUDE_HOME="$TMP_HOME/.claude"
  export CLAUDE_TOOLKIT_SKIP_ANTHROPIC=1   # skip network clone for fast tests
  export TOOLKIT_LOCAL_BIN="$TMP_HOME/.local/bin"   # don't touch real ~/.local/bin
}

teardown() {
  rm -rf "$TMP_HOME"
}

@test "install: creates skill symlinks pointing to repo" {
  run "$REPO/install.sh"
  [ "$status" -eq 0 ]
  [ -L "$CLAUDE_HOME/skills/my-preferences" ]
  [ "$(readlink "$CLAUDE_HOME/skills/my-preferences")" = "$REPO/skills/my-preferences" ]
  [ -L "$CLAUDE_HOME/skills/tdd-loop" ]
  [ -L "$CLAUDE_HOME/skills/code-review" ]
}

@test "install: creates agent symlinks" {
  run "$REPO/install.sh"
  [ "$status" -eq 0 ]
  [ -L "$CLAUDE_HOME/agents/code-explorer.md" ]
  [ -L "$CLAUDE_HOME/agents/security-scanner.md" ]
  [ -L "$CLAUDE_HOME/agents/pr-reviewer.md" ]
}

@test "install: creates hook symlinks and they are executable" {
  run "$REPO/install.sh"
  [ "$status" -eq 0 ]
  [ -L "$CLAUDE_HOME/hooks/safety-bash-guard.sh" ]
  [ -x "$CLAUDE_HOME/hooks/safety-bash-guard.sh" ]
  [ -x "$CLAUDE_HOME/hooks/precompact-handoff.sh" ]
}

@test "install: creates output-style symlink" {
  run "$REPO/install.sh"
  [ "$status" -eq 0 ]
  [ -L "$CLAUDE_HOME/output-styles/italiano-conciso.md" ]
}

@test "install: settings.json is valid JSON and contains permissions + hooks" {
  run "$REPO/install.sh"
  [ "$status" -eq 0 ]
  [ -f "$CLAUDE_HOME/settings.json" ]
  python3 -c "import json; d=json.load(open('$CLAUDE_HOME/settings.json')); assert 'permissions' in d; assert 'hooks' in d; assert 'PreToolUse' in d['hooks']"
}

@test "install: state dir and identity.md scaffolded" {
  run "$REPO/install.sh"
  [ "$status" -eq 0 ]
  [ -d "$CLAUDE_HOME/state/projects" ]
  [ -f "$CLAUDE_HOME/state/identity.md" ]
}

@test "install: is idempotent (second run succeeds without changes)" {
  run "$REPO/install.sh"
  [ "$status" -eq 0 ]
  # Snapshot symlink count
  count_before="$(find "$CLAUDE_HOME/skills" -maxdepth 1 -type l | wc -l)"
  run "$REPO/install.sh"
  [ "$status" -eq 0 ]
  count_after="$(find "$CLAUDE_HOME/skills" -maxdepth 1 -type l | wc -l)"
  [ "$count_before" = "$count_after" ]
}

@test "install: --verify exits zero on clean install" {
  "$REPO/install.sh"
  run "$REPO/install.sh" --verify
  [ "$status" -eq 0 ]
}

@test "install: aborts on non-symlink conflict in skills dir" {
  mkdir -p "$CLAUDE_HOME/skills/my-preferences"
  echo "manual file" > "$CLAUDE_HOME/skills/my-preferences/something.md"
  run "$REPO/install.sh"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "conflitto" ]] || [[ "$output" =~ "conflict" ]]
}

@test "install: preserves pre-existing settings.json entries (deep merge)" {
  mkdir -p "$CLAUDE_HOME"
  cat > "$CLAUDE_HOME/settings.json" <<'EOF'
{
  "model": "claude-opus-4-5",
  "permissions": {
    "allow": ["Bash(my-existing-cmd:*)"]
  },
  "hooks": {
    "Stop": [
      {"matcher": "", "hooks": [{"type": "command", "command": "/my/existing/hook.sh"}]}
    ]
  }
}
EOF
  run "$REPO/install.sh"
  [ "$status" -eq 0 ]
  # Existing scalar wins (model not overwritten)
  python3 -c "import json; d=json.load(open('$CLAUDE_HOME/settings.json')); assert d['model']=='claude-opus-4-5', d['model']"
  # Existing permission preserved
  python3 -c "import json; d=json.load(open('$CLAUDE_HOME/settings.json')); assert 'Bash(my-existing-cmd:*)' in d['permissions']['allow']"
  # Our permission added
  python3 -c "import json; d=json.load(open('$CLAUDE_HOME/settings.json')); assert 'Bash(rg:*)' in d['permissions']['allow']"
  # Existing Stop hook preserved
  python3 -c "import json; d=json.load(open('$CLAUDE_HOME/settings.json')); assert any('/my/existing/hook.sh' in h.get('command','') for entry in d['hooks']['Stop'] for h in entry['hooks'])"
}

@test "uninstall: removes our symlinks, preserves state dir" {
  "$REPO/install.sh"
  [ -L "$CLAUDE_HOME/skills/my-preferences" ]
  [ -d "$CLAUDE_HOME/state" ]

  run "$REPO/uninstall.sh"
  [ "$status" -eq 0 ]
  [ ! -L "$CLAUDE_HOME/skills/my-preferences" ]
  [ -d "$CLAUDE_HOME/state" ]
  [ -f "$CLAUDE_HOME/state/identity.md" ]
}

@test "uninstall: restores settings.json backup" {
  mkdir -p "$CLAUDE_HOME"
  echo '{"original": true}' > "$CLAUDE_HOME/settings.json"
  "$REPO/install.sh"

  # After install, settings should NOT be {"original": true} anymore
  ! grep -q '"original"' "$CLAUDE_HOME/settings.json"

  run "$REPO/uninstall.sh"
  [ "$status" -eq 0 ]

  # After uninstall, original is restored from backup
  grep -q '"original"' "$CLAUDE_HOME/settings.json"
}
