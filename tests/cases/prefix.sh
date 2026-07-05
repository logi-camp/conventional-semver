echo -e "\n${YELLOW}Prefix${NC}"

begin_scenario "v1.0.0 + fix → default prefix 'v' → v1.0.1"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "fix: something"
o=$(run_action "$r")
assert_eq "version_tag"          "v1.0.1" "$(get_out "$o" version_tag)"
assert_eq "previous_version_tag" "v1.0.0" "$(get_out "$o" previous_version_tag)"
end_scenario
rm_repo "$r"

begin_scenario "release-2.0.0 + fix (prefix=release-) → release-2.0.1"
r=$(new_repo); commit "$r" "chore: init"; git -C "$r" tag "release-2.0.0"
commit "$r" "fix: something"
o=$(INPUT_PREFIX=release- run_action "$r")
assert_eq "version"              "2.0.1"         "$(get_out "$o" version)"
assert_eq "version_tag"          "release-2.0.1" "$(get_out "$o" version_tag)"
assert_eq "previous_version_tag" "release-2.0.0" "$(get_out "$o" previous_version_tag)"
end_scenario
rm_repo "$r"

begin_scenario "no prior tag → previous_version_tag is empty"
r=$(new_repo); commit "$r" "chore: init"
o=$(run_action "$r")
assert_eq "previous_version_tag" "" "$(get_out "$o" previous_version_tag)"
end_scenario
rm_repo "$r"
