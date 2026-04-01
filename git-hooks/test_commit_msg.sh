#!/usr/bin/env bash
# Tests for the commit-msg hook normalizer
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/commit-msg"
PASS=0
FAIL=0
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

assert_normalized() {
  local input="$1"
  local expected="$2"
  local label="${3:-$input}"

  echo "$input" > "$TMPFILE"
  "$HOOK" "$TMPFILE" 2>/dev/null
  local got
  got=$(head -1 "$TMPFILE")

  if [[ "$got" == "$expected" ]]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $label"
    echo "  input:    $input"
    echo "  expected: $expected"
    echo "  got:      $got"
  fi
}

# --- Redundant past tense after prefix ---
assert_normalized "fix: fixed if condition" "fix: if condition" "fix: fixed → fix:"
assert_normalized "fix: fixing the build" "fix: the build" "fix: fixing → fix:"
assert_normalized "feat: added new endpoint" "feat: add new endpoint" "feat: added → feat: add"
assert_normalized "chore: added dependency" "chore: add dependency" "chore: added → chore: add"
assert_normalized "chore: updated config" "chore: update config" "chore: updated → chore: update"
assert_normalized "chore: removed legacy code" "chore: remove legacy code" "chore: removed → chore: remove"
assert_normalized "docs: added readme" "docs: add readme" "docs: added → docs: add"
assert_normalized "docs: updated guide" "docs: update guide" "docs: updated → docs: update"
assert_normalized "test: added unit tests" "test: add unit tests" "test: added → test: add"
assert_normalized "refactor: refactored auth module" "refactor: auth module" "refactor: refactored → refactor:"

# --- Non-standard prefix mapping ---
assert_normalized "phase-4: wire suggestion panel" "feat: wire suggestion panel" "phase-4 → feat"
assert_normalized "design: fix settings clickability" "style: fix settings clickability" "design → style"
assert_normalized "rfc: update embedding candidate" "docs: update embedding candidate" "rfc → docs"
assert_normalized "hotfix: patch null check" "fix: patch null check" "hotfix → fix"

# --- Scope preservation ---
assert_normalized "feat(subscription): add endpoints" "feat(subscription): add endpoints" "scope preserved"
assert_normalized "chore(dto): added types" "chore(dto): add types" "scope + past tense fix"

# --- Trailing period removal ---
assert_normalized "fix: resolve race condition." "fix: resolve race condition" "trailing period"

# --- Entire-Checkpoint artifact removal ---
assert_normalized "feat(admin): add screen type Entire-Checkpoint: 2da9d333fa77" "feat(admin): add screen type" "checkpoint removal"

# --- Lowercase first char ---
assert_normalized "fix: Fixed the build" "fix: fixed the build" "lowercase after colon"
assert_normalized "fix: API endpoint broken" "fix: API endpoint broken" "acronym stays uppercase"

# --- General past tense → imperative ---
assert_normalized "feat: changed the default" "feat: change the default" "changed → change"
assert_normalized "feat: created helper function" "feat: create helper function" "created → create"
assert_normalized "feat: enabled logging" "feat: enable logging" "enabled → enable"
assert_normalized "feat: moved file to utils" "feat: move file to utils" "moved → move"
assert_normalized "feat: replaced old parser" "feat: replace old parser" "replaced → replace"

# --- Merge commits skipped ---
echo "Merge branch 'master' into develop" > "$TMPFILE"
"$HOOK" "$TMPFILE" 2>/dev/null
got=$(head -1 "$TMPFILE")
if [[ "$got" == "Merge branch 'master' into develop" ]]; then
  PASS=$((PASS + 1))
else
  FAIL=$((FAIL + 1))
  echo "FAIL: merge commit should be skipped"
fi

# --- No prefix left alone ---
assert_normalized "initial commit" "initial commit" "no prefix"

# --- Summary ---
echo ""
echo "Results: $PASS passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
