find_latest_tag() {
  PREVIOUS_TAG=$(git tag --list "${PREFIX}*" --sort=-v:refname 2>/dev/null \
    | grep -E "^${PREFIX}[0-9]+\.[0-9]+\.[0-9]+$" \
    | head -n1 || true)

  if [ -z "$PREVIOUS_TAG" ]; then
    PREVIOUS_VERSION="$INITIAL_VERSION"
    LOG_RANGE=""
  else
    PREVIOUS_VERSION="${PREVIOUS_TAG#"${PREFIX}"}"
    LOG_RANGE="${PREVIOUS_TAG}..HEAD"
  fi
}

collect_commits() {
  if [ -n "$LOG_RANGE" ]; then
    COMMIT_LOG=$(git log "$LOG_RANGE" --pretty=format:"%s%n__BODY_SEP__%n%b%n__COMMIT_END__" 2>/dev/null || true)
  else
    COMMIT_LOG=$(git log --pretty=format:"%s%n__BODY_SEP__%n%b%n__COMMIT_END__" 2>/dev/null || true)
  fi

  LAST_COMMIT=$(git rev-parse HEAD 2>/dev/null || true)
}
