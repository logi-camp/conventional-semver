build_changelog() {
  CHANGELOG=""
  [ -n "$BREAKING_LIST" ] && CHANGELOG+="[Breaking Changes]"$'\n'"${BREAKING_LIST}"$'\n'
  [ -n "$FEAT_LIST" ]     && CHANGELOG+="[Features]"$'\n'"${FEAT_LIST}"$'\n'
  [ -n "$FIX_LIST" ]      && CHANGELOG+="[Bug Fixes]"$'\n'"${FIX_LIST}"$'\n'
  [ -n "$PERF_LIST" ]     && CHANGELOG+="[Performance Improvements]"$'\n'"${PERF_LIST}"$'\n'
  CHANGELOG="${CHANGELOG%$'\n'}"
}
