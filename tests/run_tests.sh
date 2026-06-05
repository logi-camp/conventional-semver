#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ERRORS=()
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENTRYPOINT="${SCRIPT_DIR}/../entrypoint.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

pass() { echo -e "  ${GREEN}✓${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}✗${NC} $1: $2"; FAIL=$((FAIL + 1)); ERRORS+=("$1: $2"); }

assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then pass "$name"
  else fail "$name" "expected '${expected}', got '${actual}'"; fi
}

assert_contains() {
  local name="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then pass "$name"
  else fail "$name" "'${needle}' not found in output"; fi
}

assert_not_contains() {
  local name="$1" needle="$2" haystack="$3"
  if ! echo "$haystack" | grep -qF "$needle"; then pass "$name"
  else fail "$name" "'${needle}' should not appear in output"; fi
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

# =============================================================================

echo -e "\n${BOLD}conventional-semver test suite${NC}\n"

# ---------------------------------------------------------------------------
echo -e "${YELLOW}No tags${NC}"

r=$(new_repo); commit "$r" "chore: init"
o=$(run_action "$r")
assert_eq "no-tags: version"               "0.0.1" "$(get_out "$o" version)"
assert_eq "no-tags: version_tag"           "v0.0.1" "$(get_out "$o" version_tag)"
assert_eq "no-tags: previous_version"      "0.0.0" "$(get_out "$o" previous_version)"
assert_eq "no-tags: bump"                  "patch"  "$(get_out "$o" bump)"
assert_eq "no-tags: previous_version_tag"  ""       "$(get_out "$o" previous_version_tag)"
rm_repo "$r"

r=$(new_repo); commit "$r" "feat: add login"
o=$(run_action "$r")
assert_eq "no-tags-feat: version"  "0.1.0" "$(get_out "$o" version)"
assert_eq "no-tags-feat: bump"     "minor"  "$(get_out "$o" bump)"
rm_repo "$r"

r=$(new_repo); commit "$r" "feat!: total rewrite"
o=$(run_action "$r")
assert_eq "no-tags-breaking: version"  "1.0.0" "$(get_out "$o" version)"
assert_eq "no-tags-breaking: bump"     "major"  "$(get_out "$o" bump)"
rm_repo "$r"

r=$(new_repo); commit "$r" "chore: init"
o=$(INPUT_INITIAL_VERSION=2.5.0 run_action "$r")
assert_eq "initial-version: version"  "2.5.1" "$(get_out "$o" version)"
assert_eq "initial-version: previous" "2.5.0" "$(get_out "$o" previous_version)"
rm_repo "$r"

# ---------------------------------------------------------------------------
echo -e "\n${YELLOW}Bump: feat${NC}"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat: dark mode"
o=$(run_action "$r")
assert_eq "feat: bump"    "minor"  "$(get_out "$o" bump)"
assert_eq "feat: version" "1.1.0"  "$(get_out "$o" version)"
rm_repo "$r"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat(api): add pagination"
o=$(run_action "$r")
assert_eq "feat(scope): bump"    "minor" "$(get_out "$o" bump)"
assert_eq "feat(scope): version" "1.1.0" "$(get_out "$o" version)"
rm_repo "$r"

# ---------------------------------------------------------------------------
echo -e "\n${YELLOW}Bump: fix${NC}"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v2.3.4"
commit "$r" "fix: null pointer on login"
o=$(run_action "$r")
assert_eq "fix: bump"    "patch" "$(get_out "$o" bump)"
assert_eq "fix: version" "2.3.5" "$(get_out "$o" version)"
rm_repo "$r"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "fix(auth): token expiry"
o=$(run_action "$r")
assert_eq "fix(scope): bump"    "patch" "$(get_out "$o" bump)"
assert_eq "fix(scope): version" "1.0.1" "$(get_out "$o" version)"
rm_repo "$r"

# ---------------------------------------------------------------------------
echo -e "\n${YELLOW}Bump: perf${NC}"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "perf: cache database queries"
o=$(run_action "$r")
assert_eq "perf: bump"    "patch" "$(get_out "$o" bump)"
assert_eq "perf: version" "1.0.1" "$(get_out "$o" version)"
rm_repo "$r"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "perf(db): index on users table"
o=$(run_action "$r")
assert_eq "perf(scope): bump" "patch" "$(get_out "$o" bump)"
rm_repo "$r"

# ---------------------------------------------------------------------------
echo -e "\n${YELLOW}Bump: breaking change via !${NC}"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.2.3"
commit "$r" "feat!: redesign API response format"
o=$(run_action "$r")
assert_eq "feat!: bump"    "major" "$(get_out "$o" bump)"
assert_eq "feat!: version" "2.0.0" "$(get_out "$o" version)"
rm_repo "$r"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "fix!: change return type"
o=$(run_action "$r")
assert_eq "fix!: bump" "major" "$(get_out "$o" bump)"
rm_repo "$r"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "refactor!: drop support for Node 14"
o=$(run_action "$r")
assert_eq "refactor!: bump" "major" "$(get_out "$o" bump)"
rm_repo "$r"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat(api)!: remove deprecated endpoints"
o=$(run_action "$r")
assert_eq "type(scope)!: bump"    "major" "$(get_out "$o" bump)"
assert_eq "type(scope)!: version" "2.0.0" "$(get_out "$o" version)"
rm_repo "$r"

# ---------------------------------------------------------------------------
echo -e "\n${YELLOW}Bump: BREAKING CHANGE in commit body${NC}"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit_with_body "$r" "feat: update config format" "BREAKING CHANGE: old config keys removed"
o=$(run_action "$r")
assert_eq "breaking-body: bump"    "major" "$(get_out "$o" bump)"
assert_eq "breaking-body: version" "2.0.0" "$(get_out "$o" version)"
rm_repo "$r"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit_with_body "$r" "fix: handle edge case" "BREAKING CHANGE: old param removed\nMigrate by using newParam"
o=$(run_action "$r")
assert_eq "breaking-body-fix: bump" "major" "$(get_out "$o" bump)"
rm_repo "$r"

# ---------------------------------------------------------------------------
echo -e "\n${YELLOW}Priority: major > minor > patch${NC}"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "fix: small bug"
commit "$r" "feat: new thing"
o=$(run_action "$r")
assert_eq "minor-over-patch: bump"    "minor" "$(get_out "$o" bump)"
assert_eq "minor-over-patch: version" "1.1.0" "$(get_out "$o" version)"
rm_repo "$r"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat: new thing"
commit "$r" "fix: bug"
commit "$r" "feat!: breaking"
o=$(run_action "$r")
assert_eq "major-over-all: bump"    "major" "$(get_out "$o" bump)"
assert_eq "major-over-all: version" "2.0.0" "$(get_out "$o" version)"
rm_repo "$r"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "fix: bug"
commit_with_body "$r" "fix: another" "BREAKING CHANGE: changed interface"
o=$(run_action "$r")
assert_eq "breaking-body-priority: bump" "major" "$(get_out "$o" bump)"
rm_repo "$r"

# ---------------------------------------------------------------------------
echo -e "\n${YELLOW}Default bump${NC}"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "docs: update readme"
o=$(run_action "$r")
assert_eq "default-patch: bump"    "patch" "$(get_out "$o" bump)"
assert_eq "default-patch: version" "1.0.1" "$(get_out "$o" version)"
rm_repo "$r"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "docs: update readme"
o=$(INPUT_DEFAULT_BUMP=minor run_action "$r")
assert_eq "default-minor: bump"    "minor" "$(get_out "$o" bump)"
assert_eq "default-minor: version" "1.1.0" "$(get_out "$o" version)"
rm_repo "$r"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "docs: update readme"
o=$(INPUT_DEFAULT_BUMP=major run_action "$r")
assert_eq "default-major: bump"    "major" "$(get_out "$o" bump)"
assert_eq "default-major: version" "2.0.0" "$(get_out "$o" version)"
rm_repo "$r"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "docs: update readme"
o=$(INPUT_DEFAULT_BUMP=none run_action "$r")
assert_eq "default-none: bump"    "none"  "$(get_out "$o" bump)"
assert_eq "default-none: version" "1.0.0" "$(get_out "$o" version)"
rm_repo "$r"

# ---------------------------------------------------------------------------
echo -e "\n${YELLOW}Version arithmetic${NC}"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v3.7.9"
commit "$r" "feat!: breaking"
o=$(run_action "$r")
assert_eq "major-resets-minor-patch: version" "4.0.0" "$(get_out "$o" version)"
rm_repo "$r"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.5.8"
commit "$r" "feat: something"
o=$(run_action "$r")
assert_eq "minor-resets-patch: version" "1.6.0" "$(get_out "$o" version)"
rm_repo "$r"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "docs: no bump"
o=$(INPUT_DEFAULT_BUMP=none run_action "$r")
assert_eq "none-keeps-version: version" "1.0.0" "$(get_out "$o" version)"
assert_eq "none-keeps-version: bump"    "none"  "$(get_out "$o" bump)"
rm_repo "$r"

# ---------------------------------------------------------------------------
echo -e "\n${YELLOW}Prefix${NC}"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "fix: something"
o=$(run_action "$r")
assert_eq "default-prefix: version_tag"          "v1.0.1" "$(get_out "$o" version_tag)"
assert_eq "default-prefix: previous_version_tag" "v1.0.0" "$(get_out "$o" previous_version_tag)"
rm_repo "$r"

r=$(new_repo); commit "$r" "chore: init"; git -C "$r" tag "release-2.0.0"
commit "$r" "fix: something"
o=$(INPUT_PREFIX=release- run_action "$r")
assert_eq "custom-prefix: version"     "2.0.1"         "$(get_out "$o" version)"
assert_eq "custom-prefix: version_tag" "release-2.0.1" "$(get_out "$o" version_tag)"
assert_eq "custom-prefix: previous_version_tag" "release-2.0.0" "$(get_out "$o" previous_version_tag)"
rm_repo "$r"

r=$(new_repo); commit "$r" "chore: init"
o=$(run_action "$r")
assert_eq "no-prior-tag: previous_version_tag" "" "$(get_out "$o" previous_version_tag)"
rm_repo "$r"

# ---------------------------------------------------------------------------
echo -e "\n${YELLOW}Outputs${NC}"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.3.0"
commit "$r" "feat: something"
o=$(run_action "$r")
assert_eq "outputs: previous_version"     "1.3.0" "$(get_out "$o" previous_version)"
assert_eq "outputs: previous_version_tag" "v1.3.0" "$(get_out "$o" previous_version_tag)"
assert_eq "outputs: version"              "1.4.0" "$(get_out "$o" version)"
head_sha=$(git -C "$r" rev-parse HEAD)
assert_eq "outputs: last_commit" "$head_sha" "$(get_out "$o" last_commit)"
rm_repo "$r"

# ---------------------------------------------------------------------------
echo -e "\n${YELLOW}Changelog${NC}"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat: add dark mode toggle"
commit "$r" "feat(api): add pagination support"
commit "$r" "fix: resolve null pointer on login"
commit "$r" "perf: cache database queries"
o=$(run_action "$r")
cl=$(get_multiline "$o" "changelog")
assert_contains "changelog: Features section"   "## Features"                   "$cl"
assert_contains "changelog: Bug Fixes section"  "## Bug Fixes"                  "$cl"
assert_contains "changelog: Perf section"       "## Performance Improvements"   "$cl"
assert_contains "changelog: feat entry"         "feat: add dark mode toggle"    "$cl"
assert_contains "changelog: feat(scope) entry"  "feat(api): add pagination"     "$cl"
assert_contains "changelog: fix entry"          "fix: resolve null pointer"     "$cl"
assert_contains "changelog: perf entry"         "perf: cache database queries"  "$cl"
assert_not_contains "changelog: chore absent"   "chore:"                        "$cl"
rm_repo "$r"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat!: redesign API response format"
o=$(run_action "$r")
cl=$(get_multiline "$o" "changelog")
assert_contains "changelog: Breaking Changes section" "## Breaking Changes"             "$cl"
assert_contains "changelog: breaking entry"           "feat!: redesign API response"    "$cl"
rm_repo "$r"

r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "docs: update readme"
o=$(INPUT_DEFAULT_BUMP=none run_action "$r")
cl=$(get_multiline "$o" "changelog")
assert_eq "changelog: empty when no conv commits" "" "$cl"
rm_repo "$r"

# ---------------------------------------------------------------------------
echo -e "\n${YELLOW}Validation${NC}"

r=$(new_repo); commit "$r" "chore: init"
rc=0
(
  cd "$r"
  INPUT_PREFIX=v INPUT_DEFAULT_BUMP=bogus INPUT_INITIAL_VERSION=0.0.0 \
  GITHUB_OUTPUT=/dev/null bash "$ENTRYPOINT" >/dev/null 2>&1
) || rc=$?
if [ "$rc" -ne 0 ]; then pass "invalid-bump: exits non-zero"
else fail "invalid-bump: exits non-zero" "expected non-zero exit, got 0"; fi
rm_repo "$r"

# =============================================================================
echo ""
echo -e "${BOLD}Results: ${GREEN}${PASS} passed${NC}  ${RED}${FAIL} failed${NC}"

if [ "${#ERRORS[@]}" -gt 0 ]; then
  echo -e "\nFailed tests:"
  for e in "${ERRORS[@]}"; do
    echo -e "  ${RED}✗${NC} $e"
  done
  exit 1
fi
