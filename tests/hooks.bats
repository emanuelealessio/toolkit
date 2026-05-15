#!/usr/bin/env bats
# hooks.bats — tests for safety-bash-guard.sh behavior.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  GUARD="$REPO/hooks/safety-bash-guard.sh"
}

@test "guard: warns on git push --force on main" {
  run bash -c "echo '{\"tool_input\":{\"command\":\"git push --force origin main\"}}' | $GUARD"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "RISCHIO" ]] || [[ "$output" =~ "safety-guard" ]]
}

@test "guard: warns on git push -f main" {
  run bash -c "echo '{\"tool_input\":{\"command\":\"git push -f origin main\"}}' | $GUARD"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "safety-guard" ]]
}

@test "guard: warns on git reset --hard" {
  run bash -c "echo '{\"tool_input\":{\"command\":\"git reset --hard HEAD~3\"}}' | $GUARD"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "reset --hard" ]]
}

@test "guard: warns on rm -rf /" {
  run bash -c "echo '{\"tool_input\":{\"command\":\"rm -rf /\"}}' | $GUARD"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "ESTREMO" ]] || [[ "$output" =~ "safety-guard" ]]
}

@test "guard: warns on rm -rf .git" {
  run bash -c "echo '{\"tool_input\":{\"command\":\"rm -rf .git\"}}' | $GUARD"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "\.git" ]] || [[ "$output" =~ "safety-guard" ]]
}

@test "guard: warns on --no-verify commit" {
  run bash -c "echo '{\"tool_input\":{\"command\":\"git commit --no-verify -m wip\"}}' | $GUARD"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "no-verify" ]]
}

@test "guard: silent on safe commands (ls)" {
  run bash -c "echo '{\"tool_input\":{\"command\":\"ls -la\"}}' | $GUARD"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "guard: silent on safe commands (git status)" {
  run bash -c "echo '{\"tool_input\":{\"command\":\"git status\"}}' | $GUARD"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "guard: silent on git push without force" {
  run bash -c "echo '{\"tool_input\":{\"command\":\"git push origin feature-branch\"}}' | $GUARD"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "guard: handles empty command without crashing" {
  run bash -c "echo '{\"tool_input\":{\"command\":\"\"}}' | $GUARD"
  [ "$status" -eq 0 ]
}

@test "guard: handles malformed JSON gracefully" {
  run bash -c "echo 'not json' | $GUARD"
  [ "$status" -eq 0 ]
}
