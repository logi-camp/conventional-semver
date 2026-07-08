echo -e "\n${YELLOW}Changelog${NC}"

begin_scenario "v1.0.0 + feat, feat(scope), fix, perf → grouped changelog"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat: add dark mode toggle"
commit "$r" "feat(api): add pagination support"
commit "$r" "fix: resolve null pointer on login"
commit "$r" "perf: cache database queries"
o=$(run_action "$r")
cl=$(get_multiline "$o" "changelog")
assert_contains     "Features section"       "[Features]"                  "$cl"
assert_contains     "Bug Fixes section"       "[Bug Fixes]"                "$cl"
assert_contains     "Perf section"            "[Performance Improvements]" "$cl"
assert_contains     "feat entry"              "feat: add dark mode toggle"  "$cl"
assert_contains     "feat(scope) entry"       "feat(api): add pagination"   "$cl"
assert_contains     "fix entry"               "fix: resolve null pointer"   "$cl"
assert_contains     "perf entry"              "perf: cache database queries" "$cl"
assert_not_contains "no chore entry"          "chore:"                      "$cl"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + feat! → Breaking Changes section"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat!: redesign API response format"
o=$(run_action "$r")
cl=$(get_multiline "$o" "changelog")
assert_contains "Breaking Changes section" "[Breaking Changes]"          "$cl"
assert_contains "breaking entry"           "feat!: redesign API response" "$cl"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + feat body: BREAKING CHANGE → Breaking Changes section"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit_with_body "$r" "feat: update config format" "BREAKING CHANGE: old config keys removed"
o=$(run_action "$r")
cl=$(get_multiline "$o" "changelog")
assert_contains "Breaking Changes section" "[Breaking Changes]"      "$cl"
assert_contains "breaking entry"           "feat: update config format" "$cl"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + docs (default_bump=none) → empty changelog"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "docs: update readme"
o=$(INPUT_DEFAULT_BUMP=none run_action "$r")
cl=$(get_multiline "$o" "changelog")
assert_eq "changelog" "" "$cl"
end_scenario
rm_repo "$r"

echo -e "\n${YELLOW}Changelog: printed output${NC}"

begin_scenario "print: all commit types grouped"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat!: redesign API response format"
commit "$r" "feat: add dark mode toggle"
commit "$r" "feat(ui): add button component"
commit "$r" "fix: resolve null pointer on login"
commit "$r" "fix(auth): handle expired tokens"
commit "$r" "perf: cache database queries"
commit "$r" "chore: update dependencies"
o=$(run_action "$r")
cl=$(get_multiline "$o" "changelog")
echo -e "  ${BOLD}--- changelog (all types) ---${NC}"
echo "$cl" | sed 's/^/    /'
echo -e "  ${BOLD}--- end ---${NC}"
assert_contains "Breaking Changes" "[Breaking Changes]" "$cl"
assert_contains "Features"         "[Features]"         "$cl"
assert_contains "Bug Fixes"        "[Bug Fixes]"        "$cl"
assert_contains "Performance"      "[Performance"        "$cl"
assert_not_contains "no chore"     "chore:"              "$cl"
end_scenario
rm_repo "$r"

begin_scenario "print: feat + fix + breaking body (user's test case)"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat: add some feat"
commit "$r" "feat: this is the second feat"
commit "$r" "fix: first issue"
commit "$r" "fix: this is the second fix"
commit_with_body "$r" "feat: redesign config" "BREAKING CHANGE: old config keys removed"
o=$(run_action "$r")
cl=$(get_multiline "$o" "changelog")
echo -e "  ${BOLD}--- changelog (feat + fix + breaking body) ---${NC}"
echo "$cl" | sed 's/^/    /'
echo -e "  ${BOLD}--- end ---${NC}"
assert_contains "Breaking Changes" "[Breaking Changes]"     "$cl"
assert_contains "breaking entry"   "feat: redesign config"   "$cl"
assert_contains "Features"         "[Features]"             "$cl"
assert_contains "Bug Fixes"        "[Bug Fixes]"            "$cl"
end_scenario
rm_repo "$r"

begin_scenario "print: only breaking via body"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit_with_body "$r" "fix: handle edge case" "BREAKING CHANGE: old param removed"
o=$(run_action "$r")
cl=$(get_multiline "$o" "changelog")
echo -e "  ${BOLD}--- changelog (breaking body only) ---${NC}"
echo "$cl" | sed 's/^/    /'
echo -e "  ${BOLD}--- end ---${NC}"
assert_contains "Breaking Changes" "[Breaking Changes]"    "$cl"
assert_contains "breaking entry"   "fix: handle edge case"  "$cl"
assert_not_contains "no Features"  "[Features]"            "$cl"
assert_not_contains "no Bug Fixes" "[Bug Fixes]"           "$cl"
end_scenario
rm_repo "$r"

begin_scenario "print: breaking via ! mixed with regular commits"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat: add user profiles"
commit "$r" "feat!: change auth API"
commit "$r" "fix: typo in error message"
o=$(run_action "$r")
cl=$(get_multiline "$o" "changelog")
echo -e "  ${BOLD}--- changelog (feat! mixed) ---${NC}"
echo "$cl" | sed 's/^/    /'
echo -e "  ${BOLD}--- end ---${NC}"
assert_contains "Breaking Changes" "[Breaking Changes]"    "$cl"
assert_contains "breaking entry"   "feat!: change auth API" "$cl"
assert_contains "Features"         "[Features]"            "$cl"
assert_contains "feat entry"       "feat: add user profiles" "$cl"
assert_contains "Bug Fixes"        "[Bug Fixes]"           "$cl"
assert_contains "fix entry"        "fix: typo in error"     "$cl"
end_scenario
rm_repo "$r"

begin_scenario "print: empty changelog (non-conventional commits)"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "chore: update deps"
commit "$r" "docs: update readme"
o=$(INPUT_DEFAULT_BUMP=none run_action "$r")
cl=$(get_multiline "$o" "changelog")
echo -e "  ${BOLD}--- changelog (empty) ---${NC}"
if [ -z "$cl" ]; then
  echo -e "    ${GREEN}(empty)${NC}"
else
  echo "$cl" | sed 's/^/    /'
fi
echo -e "  ${BOLD}--- end ---${NC}"
assert_eq "changelog" "" "$cl"
end_scenario
rm_repo "$r"
