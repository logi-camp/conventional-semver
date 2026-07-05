echo -e "\n${YELLOW}Outputs${NC}"

begin_scenario "v1.3.0 + feat → all outputs populated"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.3.0"
commit "$r" "feat: something"
o=$(run_action "$r")
assert_eq "previous_version"     "1.3.0"  "$(get_out "$o" previous_version)"
assert_eq "previous_version_tag" "v1.3.0" "$(get_out "$o" previous_version_tag)"
assert_eq "version"              "1.4.0"  "$(get_out "$o" version)"
head_sha=$(git -C "$r" rev-parse HEAD)
assert_eq "last_commit" "$head_sha" "$(get_out "$o" last_commit)"
end_scenario
rm_repo "$r"
