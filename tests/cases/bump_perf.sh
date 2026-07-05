echo -e "\n${YELLOW}Bump: perf${NC}"

begin_scenario "v1.0.0 + perf → patch → 1.0.1"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "perf: cache database queries"
o=$(run_action "$r")
assert_eq "bump"    "patch" "$(get_out "$o" bump)"
assert_eq "version" "1.0.1" "$(get_out "$o" version)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + perf(scope) → patch → 1.0.1"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "perf(db): index on users table"
o=$(run_action "$r")
assert_eq "bump" "patch" "$(get_out "$o" bump)"
end_scenario
rm_repo "$r"
