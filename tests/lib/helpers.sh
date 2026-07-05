SCENARIO_ERRORS=()

begin_scenario() {
  SCENARIO_ERRORS=()
  CURRENT_SCENARIO="$1"
}

end_scenario() {
  if [ "${#SCENARIO_ERRORS[@]}" -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} ${CURRENT_SCENARIO}"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✗${NC} ${CURRENT_SCENARIO}"
    for e in "${SCENARIO_ERRORS[@]}"; do
      echo -e "    ${RED}${e}${NC}"
    done
    FAIL=$((FAIL + 1))
    ERRORS+=("$CURRENT_SCENARIO")
  fi
}

assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [ "$expected" != "$actual" ]; then
    SCENARIO_ERRORS+=("${name}: expected '${expected}', got '${actual}'")
  fi
}

assert_contains() {
  local name="$1" needle="$2" haystack="$3"
  if ! echo "$haystack" | grep -qF "$needle"; then
    SCENARIO_ERRORS+=("${name}: '${needle}' not found")
  fi
}

assert_not_contains() {
  local name="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    SCENARIO_ERRORS+=("${name}: '${needle}' should not appear")
  fi
}

new_repo() {
  local dir
  dir=$(mktemp -d)
  git init "$dir" -q
  git -C "$dir" config user.email "ci@test.local"
  git -C "$dir" config user.name "CI Test"
  echo "$dir"
}

commit() {
  local repo="$1"; shift
  git -C "$repo" commit --allow-empty -m "$@" -q
}

commit_with_body() {
  local repo="$1" subject="$2" body="$3"
  git -C "$repo" commit --allow-empty -m "$subject" -m "$body" -q
}

tag() { git -C "$1" tag "$2"; }

run_action() {
  local repo="$1"
  local out
  out=$(mktemp)
  (
    cd "$repo"
    INPUT_PREFIX="${INPUT_PREFIX:-v}" \
    INPUT_DEFAULT_BUMP="${INPUT_DEFAULT_BUMP:-patch}" \
    INPUT_INITIAL_VERSION="${INPUT_INITIAL_VERSION:-0.0.0}" \
    INPUT_PRERELEASE="${INPUT_PRERELEASE:-}" \
    INPUT_PRERELEASE_IDENTIFIER="${INPUT_PRERELEASE_IDENTIFIER:-numbered}" \
    INPUT_INCLUDE_SHA="${INPUT_INCLUDE_SHA:-auto}" \
    GITHUB_OUTPUT="$out" \
    bash "$ENTRYPOINT" >/dev/null
  )
  echo "$out"
}

get_out() {
  local file="$1" key="$2"
  grep "^${key}=" "$file" 2>/dev/null | head -n1 | cut -d= -f2- || true
}

get_multiline() {
  local file="$1" key="$2"
  awk -v key="$key" '
    $0 ~ ("^" key "<<") { delim=substr($0, length(key "<<")+1); in_block=1; next }
    in_block && $0==delim { in_block=0; next }
    in_block { print }
  ' "$file" 2>/dev/null || true
}

rm_repo() { rm -rf "$1"; }