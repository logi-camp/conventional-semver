echo -e "\n${YELLOW}Validation${NC}"

begin_scenario "default_bump=bogus → exits non-zero"
r=$(new_repo); commit "$r" "chore: init"
rc=0
(
  cd "$r"
  INPUT_PREFIX=v INPUT_DEFAULT_BUMP=bogus INPUT_INITIAL_VERSION=0.0.0 \
  GITHUB_OUTPUT=/dev/null bash "$ENTRYPOINT" >/dev/null 2>&1
) || rc=$?
if [ "$rc" -ne 0 ]; then
  :
else
  SCENARIO_ERRORS+=("expected non-zero exit, got 0")
fi
end_scenario
rm_repo "$r"
