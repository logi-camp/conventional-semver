echo -e "\n${YELLOW}Version arithmetic${NC}"

begin_scenario "v3.7.9 + feat! → major resets minor+patch → 4.0.0"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v3.7.9"
commit "$r" "feat!: breaking"
o=$(run_action "$r")
assert_eq "version" "4.0.0" "$(get_out "$o" version)"
end_scenario
rm_repo "$r"

begin_scenario "v1.5.8 + feat → minor resets patch → 1.6.0"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.5.8"
commit "$r" "feat: something"
o=$(run_action "$r")
assert_eq "version" "1.6.0" "$(get_out "$o" version)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + docs (default_bump=none) → no change → 1.0.0"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "docs: no bump"
o=$(INPUT_DEFAULT_BUMP=none run_action "$r")
assert_eq "version" "1.0.0" "$(get_out "$o" version)"
assert_eq "bump"    "none"  "$(get_out "$o" bump)"
end_scenario
rm_repo "$r"
