echo -e "\n${YELLOW}Bump: feat${NC}"

begin_scenario "v1.0.0 + feat → minor → 1.1.0"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat: dark mode"
o=$(run_action "$r")
assert_eq "bump"    "minor" "$(get_out "$o" bump)"
assert_eq "version" "1.1.0" "$(get_out "$o" version)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + feat(scope) → minor → 1.1.0"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat(api): add pagination"
o=$(run_action "$r")
assert_eq "bump"    "minor" "$(get_out "$o" bump)"
assert_eq "version" "1.1.0" "$(get_out "$o" version)"
end_scenario
rm_repo "$r"
