echo -e "\n${YELLOW}Changelog${NC}"

begin_scenario "v1.0.0 + feat, feat(scope), fix, perf → grouped changelog"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat: add dark mode toggle"
commit "$r" "feat(api): add pagination support"
commit "$r" "fix: resolve null pointer on login"
commit "$r" "perf: cache database queries"
o=$(run_action "$r")
cl=$(get_multiline "$o" "changelog")
assert_contains     "Features section"       "## Features"                  "$cl"
assert_contains     "Bug Fixes section"       "## Bug Fixes"                "$cl"
assert_contains     "Perf section"            "## Performance Improvements" "$cl"
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
assert_contains "Breaking Changes section" "## Breaking Changes"          "$cl"
assert_contains "breaking entry"           "feat!: redesign API response" "$cl"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + feat body: BREAKING CHANGE → Breaking Changes section"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit_with_body "$r" "feat: update config format" "BREAKING CHANGE: old config keys removed"
o=$(run_action "$r")
cl=$(get_multiline "$o" "changelog")
assert_contains "Breaking Changes section" "## Breaking Changes"      "$cl"
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
