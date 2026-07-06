classify_commits() {
  HAS_BREAKING=false
  HAS_FEAT=false
  HAS_PATCH=false

  BREAKING_LIST=""
  FEAT_LIST=""
  FIX_LIST=""
  PERF_LIST=""

  local subject=""
  local body=""
  local reading_body=false

  while IFS= read -r line; do
    if [ "$line" = "__COMMIT_END__" ]; then
      _classify_single_commit "$subject" "$body"
      subject=""
      body=""
      reading_body=false
    elif [ "$line" = "__BODY_SEP__" ]; then
      reading_body=true
    elif [ "$reading_body" = false ]; then
      subject="$line"
    else
      if [ -n "$body" ]; then
        body+=$'\n'"$line"
      else
        body="$line"
      fi
    fi
  done <<< "$COMMIT_LOG"
}

_classify_single_commit() {
  local subject="$1"
  local body="$2"

  [ -z "$subject" ] && return 0

  local is_breaking=false

  if echo "$subject" | grep -qE "^[a-zA-Z]+(\([^)]*\))?!:"; then
    is_breaking=true
  fi

  if [ -n "$body" ] && echo "$body" | grep -q "^BREAKING CHANGE:"; then
    is_breaking=true
  fi

  if [ "$is_breaking" = true ]; then
    HAS_BREAKING=true
    BREAKING_LIST="${BREAKING_LIST}- ${subject}"$'\n'
  elif echo "$subject" | grep -qE "^feat(\([^)]*\))?:"; then
    HAS_FEAT=true
    FEAT_LIST="${FEAT_LIST}- ${subject}"$'\n'
  elif echo "$subject" | grep -qE "^fix(\([^)]*\))?:"; then
    HAS_PATCH=true
    FIX_LIST="${FIX_LIST}- ${subject}"$'\n'
  elif echo "$subject" | grep -qE "^perf(\([^)]*\))?:"; then
    HAS_PATCH=true
    PERF_LIST="${PERF_LIST}- ${subject}"$'\n'
  fi
}
