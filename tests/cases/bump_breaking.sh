echo -e "\n${YELLOW}Bump: breaking change via !${NC}"

begin_scenario "v1.2.3 + feat! → major → 2.0.0"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.2.3"
commit "$r" "feat!: redesign API response format"
o=$(run_action "$r")
assert_eq "bump"    "major" "$(get_out "$o" bump)"
assert_eq "version" "2.0.0" "$(get_out "$o" version)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + fix! → major → 2.0.0"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "fix!: change return type"
o=$(run_action "$r")
assert_eq "bump" "major" "$(get_out "$o" bump)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + refactor! → major → 2.0.0"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "refactor!: drop support for Node 14"
o=$(run_action "$r")
assert_eq "bump" "major" "$(get_out "$o" bump)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + feat(scope)! → major → 2.0.0"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat(api)!: remove deprecated endpoints"
o=$(run_action "$r")
assert_eq "bump"    "major" "$(get_out "$o" bump)"
assert_eq "version" "2.0.0" "$(get_out "$o" version)"
end_scenario
rm_repo "$r"

echo -e "\n${YELLOW}Bump: BREAKING CHANGE in commit body${NC}"

begin_scenario "v1.0.0 + feat body: BREAKING CHANGE → major → 2.0.0"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit_with_body "$r" "feat: update config format" "BREAKING CHANGE: old config keys removed"
o=$(run_action "$r")
assert_eq "bump"    "major" "$(get_out "$o" bump)"
assert_eq "version" "2.0.0" "$(get_out "$o" version)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + fix body: BREAKING CHANGE → major → 2.0.0"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit_with_body "$r" "fix: handle edge case" "BREAKING CHANGE: old param removed\nMigrate by using newParam"
o=$(run_action "$r")
assert_eq "bump" "major" "$(get_out "$o" bump)"
end_scenario
rm_repo "$r"
