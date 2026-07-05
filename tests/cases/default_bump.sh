echo -e "\n${YELLOW}Default bump${NC}"

begin_scenario "v1.0.0 + docs (default_bump=patch) → patch → 1.0.1"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "docs: update readme"
o=$(run_action "$r")
assert_eq "bump"    "patch" "$(get_out "$o" bump)"
assert_eq "version" "1.0.1" "$(get_out "$o" version)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + docs (default_bump=minor) → minor → 1.1.0"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "docs: update readme"
o=$(INPUT_DEFAULT_BUMP=minor run_action "$r")
assert_eq "bump"    "minor" "$(get_out "$o" bump)"
assert_eq "version" "1.1.0" "$(get_out "$o" version)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + docs (default_bump=major) → major → 2.0.0"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "docs: update readme"
o=$(INPUT_DEFAULT_BUMP=major run_action "$r")
assert_eq "bump"    "major" "$(get_out "$o" bump)"
assert_eq "version" "2.0.0" "$(get_out "$o" version)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + docs (default_bump=none) → none → 1.0.0"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "docs: update readme"
o=$(INPUT_DEFAULT_BUMP=none run_action "$r")
assert_eq "bump"    "none"  "$(get_out "$o" bump)"
assert_eq "version" "1.0.0" "$(get_out "$o" version)"
end_scenario
rm_repo "$r"
