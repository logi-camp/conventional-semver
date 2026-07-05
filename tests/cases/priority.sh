echo -e "\n${YELLOW}Priority: major > minor > patch${NC}"

begin_scenario "v1.0.0 + fix, feat → minor wins → 1.1.0"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "fix: small bug"
commit "$r" "feat: new thing"
o=$(run_action "$r")
assert_eq "bump"    "minor" "$(get_out "$o" bump)"
assert_eq "version" "1.1.0" "$(get_out "$o" version)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + feat, fix, feat! → major wins → 2.0.0"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat: new thing"
commit "$r" "fix: bug"
commit "$r" "feat!: breaking"
o=$(run_action "$r")
assert_eq "bump"    "major" "$(get_out "$o" bump)"
assert_eq "version" "2.0.0" "$(get_out "$o" version)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + fix, fix BREAKING CHANGE body → major wins → 2.0.0"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "fix: bug"
commit_with_body "$r" "fix: another" "BREAKING CHANGE: changed interface"
o=$(run_action "$r")
assert_eq "bump" "major" "$(get_out "$o" bump)"
end_scenario
rm_repo "$r"
