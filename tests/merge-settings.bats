#!/usr/bin/env bats
# merge-settings.bats — unit tests for lib/merge-settings.py.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  TMP="$(mktemp -d -t merge-test-XXXXXX)"
  MERGE="$REPO/lib/merge-settings.py"
}

teardown() {
  rm -rf "$TMP"
}

@test "merge: creates target if missing" {
  cat > "$TMP/fragment.json" <<'EOF'
{"key": "value"}
EOF
  run python3 "$MERGE" "$TMP/fragment.json" "$TMP/target.json"
  [ "$status" -eq 0 ]
  [ -f "$TMP/target.json" ]
  grep -q '"key"' "$TMP/target.json"
}

@test "merge: deep merges nested dicts" {
  cat > "$TMP/fragment.json" <<'EOF'
{"permissions": {"allow": ["new-perm"], "deny": ["new-deny"]}}
EOF
  cat > "$TMP/target.json" <<'EOF'
{"permissions": {"allow": ["existing-perm"]}}
EOF
  run python3 "$MERGE" "$TMP/fragment.json" "$TMP/target.json"
  [ "$status" -eq 0 ]
  python3 -c "import json; d=json.load(open('$TMP/target.json')); assert 'existing-perm' in d['permissions']['allow']; assert 'new-perm' in d['permissions']['allow']; assert 'new-deny' in d['permissions']['deny']"
}

@test "merge: lists union without duplicates" {
  cat > "$TMP/fragment.json" <<'EOF'
{"items": ["a", "b", "c"]}
EOF
  cat > "$TMP/target.json" <<'EOF'
{"items": ["a", "x"]}
EOF
  run python3 "$MERGE" "$TMP/fragment.json" "$TMP/target.json"
  [ "$status" -eq 0 ]
  python3 -c "import json; d=json.load(open('$TMP/target.json')); assert d['items']==['a','x','b','c'], d['items']"
}

@test "merge: existing scalar wins (never overwritten)" {
  cat > "$TMP/fragment.json" <<'EOF'
{"model": "from-fragment", "outputStyle": "from-fragment"}
EOF
  cat > "$TMP/target.json" <<'EOF'
{"model": "existing-value"}
EOF
  run python3 "$MERGE" "$TMP/fragment.json" "$TMP/target.json"
  [ "$status" -eq 0 ]
  python3 -c "import json; d=json.load(open('$TMP/target.json')); assert d['model']=='existing-value'; assert d['outputStyle']=='from-fragment'"
}

@test "merge: preserves existing keys not in fragment" {
  cat > "$TMP/fragment.json" <<'EOF'
{"new-key": "value"}
EOF
  cat > "$TMP/target.json" <<'EOF'
{"untouched": "stays", "deep": {"nested": "kept"}}
EOF
  run python3 "$MERGE" "$TMP/fragment.json" "$TMP/target.json"
  [ "$status" -eq 0 ]
  python3 -c "import json; d=json.load(open('$TMP/target.json')); assert d['untouched']=='stays'; assert d['deep']['nested']=='kept'; assert d['new-key']=='value'"
}

@test "merge: writes atomically (no temp file left behind on success)" {
  cat > "$TMP/fragment.json" <<'EOF'
{"x": 1}
EOF
  python3 "$MERGE" "$TMP/fragment.json" "$TMP/target.json"
  # No .tmp file should remain
  [ -z "$(find "$TMP" -name '.settings.*.tmp' 2>/dev/null)" ]
}

@test "merge: produces valid JSON output" {
  cat > "$TMP/fragment.json" <<'EOF'
{"a": {"b": [1, 2]}, "c": "string"}
EOF
  cat > "$TMP/target.json" <<'EOF'
{"a": {"d": "kept"}, "list": ["one"]}
EOF
  python3 "$MERGE" "$TMP/fragment.json" "$TMP/target.json"
  python3 -c "import json; json.load(open('$TMP/target.json'))"
}
