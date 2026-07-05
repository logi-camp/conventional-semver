echo -e "\n${YELLOW}Bump: fix${NC}"

begin_scenario "v2.3.4 + fix → patch → 2.3.5"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v2.3.4"
commit "$r" "fix: null pointer on login"
o=$(run_action "$r")
assert_eq "bump"    "patch" "$(get_out "$o" bump)"
assert_eq "version" "2.3.5" "$(get_out "$o" version)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + fix(scope) → patch → 1.0.1"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "fix(auth): token expiry"
o=$(run_action "$r")
assert_eq "bump"    "patch" "$(get_out "$o" bump)"
assert_eq "version" "1.0.1" "$(get_out "$o" version)"
end_scenario
rm_repo "$r"
