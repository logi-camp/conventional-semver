echo -e "\n${YELLOW}Pre-release${NC}"

begin_scenario "v1.0.0 + feat (prerelease=rc, no SHA) → 1.1.0-rc.1"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat: new feature"
INPUT_PRERELEASE=rc INPUT_INCLUDE_SHA=false o=$(run_action "$r")
assert_eq "version"       "1.1.0-rc.1"       "$(get_out "$o" version)"
assert_eq "version_tag"   "v1.1.0-rc.1"      "$(get_out "$o" version_tag)"
assert_eq "base_version"  "1.1.0"             "$(get_out "$o" base_version)"
assert_eq "base_tag"      "v1.1.0"            "$(get_out "$o" base_version_tag)"
assert_eq "rc_number"     "1"                 "$(get_out "$o" rc_number)"
assert_eq "bump"          "minor"             "$(get_out "$o" bump)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + feat, tag v1.1.0-rc.1, + feat → 1.1.0-rc.2"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat: first"
tag "$r" "v1.1.0-rc.1"
commit "$r" "feat: second"
INPUT_PRERELEASE=rc INPUT_INCLUDE_SHA=false o=$(run_action "$r")
assert_eq "version"   "1.1.0-rc.2"  "$(get_out "$o" version)"
assert_eq "rc_number" "2"            "$(get_out "$o" rc_number)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + feat (prerelease=rc, SHA=auto) → 1.1.0-rc.1-<sha>"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat: new feature"
INPUT_PRERELEASE=rc INPUT_INCLUDE_SHA=auto o=$(run_action "$r")
head_sha=$(git -C "$r" rev-parse --short=7 HEAD)
assert_contains "version contains sha" "$head_sha" "$(get_out "$o" version)"
assert_contains "tag contains sha"     "$head_sha" "$(get_out "$o" version_tag)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + feat (prerelease=rc, SHA=false) → 1.1.0-rc.1 (no sha)"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat: new feature"
INPUT_PRERELEASE=rc INPUT_INCLUDE_SHA=false o=$(run_action "$r")
head_sha=$(git -C "$r" rev-parse --short=7 HEAD)
assert_not_contains "version clean" "$head_sha" "$(get_out "$o" version)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + feat (prerelease=alpha, no SHA) → 1.1.0-alpha.1"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat: experimental"
INPUT_PRERELEASE=alpha INPUT_INCLUDE_SHA=false o=$(run_action "$r")
assert_eq "version"     "1.1.0-alpha.1"  "$(get_out "$o" version)"
assert_eq "version_tag" "v1.1.0-alpha.1" "$(get_out "$o" version_tag)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + feat (no prerelease) → base_version=1.1.0"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "feat: something"
INPUT_PRERELEASE="" o=$(run_action "$r")
assert_eq "base_version" "1.1.0"  "$(get_out "$o" base_version)"
assert_eq "base_tag"     "v1.1.0" "$(get_out "$o" base_version_tag)"
assert_eq "version"      "1.1.0"  "$(get_out "$o" version)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + fix (no prerelease) → no rc_number output"
r=$(new_repo); commit "$r" "chore: init"; tag "$r" "v1.0.0"
commit "$r" "fix: bug"
INPUT_PRERELEASE="" o=$(run_action "$r")
assert_eq "rc_number" "" "$(get_out "$o" rc_number)"
end_scenario
rm_repo "$r"

echo -e "\n${YELLOW}Pre-release with SHA identifier${NC}"

begin_scenario "v1.0.0 + feat (prerelease=rc, prerelease_identifier=sha) → 1.1.0-rc.<sha>"
r=$(new_repo); 
git -C "$r" checkout -b main
commit "$r" "chore: init"
tag "$r" "v1.0.0"
git -C "$r" checkout -b release
commit "$r" "feat: new feature"
INPUT_PRERELEASE=rc INPUT_PRERELEASE_IDENTIFIER=sha INPUT_INCLUDE_SHA=false o=$(run_action "$r")
head_sha=$(git -C "$r" rev-parse --short=7 HEAD)
expected="1.1.0-rc.${head_sha}"
assert_eq "version"     "${expected}"       "$(get_out "$o" version)"
assert_eq "base_version" "1.1.0"           "$(get_out "$o" base_version)"
assert_eq "rc_number"    "${head_sha}"      "$(get_out "$o" rc_number)"
assert_eq "bump"         "minor"           "$(get_out "$o" bump)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 + fix (prerelease=beta, prerelease_identifier=sha) → 1.0.1-beta.<sha>"
r=$(new_repo); 
git -C "$r" checkout -b main
commit "$r" "chore: init"
tag "$r" "v1.0.0"
git -C "$r" checkout -b test
commit "$r" "fix: bug fix"
INPUT_PRERELEASE=beta INPUT_PRERELEASE_IDENTIFIER=sha INPUT_INCLUDE_SHA=false o=$(run_action "$r")
head_sha=$(git -C "$r" rev-parse --short=7 HEAD)
expected="1.0.1-beta.${head_sha}"
assert_eq "version"     "${expected}"  "$(get_out "$o" version)"
assert_eq "rc_number"    "${head_sha}"  "$(get_out "$o" rc_number)"
end_scenario
rm_repo "$r"

begin_scenario "v1.0.0 (prerelease=rc, prerelease_identifier=sha, no commits) → 1.0.1-rc.<sha>"
r=$(new_repo); 
git -C "$r" checkout -b main
commit "$r" "chore: init"
tag "$r" "v1.0.0"
git -C "$r" checkout -b release
INPUT_PRERELEASE=rc INPUT_PRERELEASE_IDENTIFIER=sha INPUT_INCLUDE_SHA=false o=$(run_action "$r")
head_sha=$(git -C "$r" rev-parse --short=7 HEAD)
expected="1.0.1-rc.${head_sha}"
assert_eq "version"     "${expected}"  "$(get_out "$o" version)"
assert_eq "rc_number"    "${head_sha}"  "$(get_out "$o" rc_number)"
assert_eq "bump"         "patch"      "$(get_out "$o" bump)"
end_scenario
rm_repo "$r"