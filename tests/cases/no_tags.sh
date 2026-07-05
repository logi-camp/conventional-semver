echo -e "${YELLOW}No tags${NC}"

begin_scenario "no tags + chore → patch from 0.0.0 → 0.0.1"
r=$(new_repo); commit "$r" "chore: init"
o=$(run_action "$r")
assert_eq "version"               "0.0.1"  "$(get_out "$o" version)"
assert_eq "version_tag"           "v0.0.1" "$(get_out "$o" version_tag)"
assert_eq "previous_version"      "0.0.0"  "$(get_out "$o" previous_version)"
assert_eq "bump"                  "patch"  "$(get_out "$o" bump)"
assert_eq "previous_version_tag"  ""       "$(get_out "$o" previous_version_tag)"
end_scenario
rm_repo "$r"

begin_scenario "no tags + feat → minor from 0.0.0 → 0.1.0"
r=$(new_repo); commit "$r" "feat: add login"
o=$(run_action "$r")
assert_eq "version" "0.1.0" "$(get_out "$o" version)"
assert_eq "bump"    "minor" "$(get_out "$o" bump)"
end_scenario
rm_repo "$r"

begin_scenario "no tags + breaking → major from 0.0.0 → 1.0.0"
r=$(new_repo); commit "$r" "feat!: total rewrite"
o=$(run_action "$r")
assert_eq "version" "1.0.0" "$(get_out "$o" version)"
assert_eq "bump"    "major" "$(get_out "$o" bump)"
end_scenario
rm_repo "$r"

begin_scenario "no tags + initial_version=2.5.0 + chore → patch → 2.5.1"
r=$(new_repo); commit "$r" "chore: init"
o=$(INPUT_INITIAL_VERSION=2.5.0 run_action "$r")
assert_eq "version"  "2.5.1" "$(get_out "$o" version)"
assert_eq "previous" "2.5.0" "$(get_out "$o" previous_version)"
end_scenario
rm_repo "$r"
