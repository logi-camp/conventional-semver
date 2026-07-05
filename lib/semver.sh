parse_semver() {
  IFS='.' read -r MAJOR MINOR PATCH <<< "$PREVIOUS_VERSION"
  MAJOR="${MAJOR:-0}"
  MINOR="${MINOR:-0}"
  PATCH="${PATCH:-0}"
}

determine_bump() {
  if [ "$HAS_BREAKING" = true ]; then
    BUMP="major"
  elif [ "$HAS_FEAT" = true ]; then
    BUMP="minor"
  elif [ "$HAS_PATCH" = true ]; then
    BUMP="patch"
  else
    BUMP="$DEFAULT_BUMP"
  fi
}

calculate_version() {
  NEW_MAJOR="$MAJOR"
  NEW_MINOR="$MINOR"
  NEW_PATCH="$PATCH"

  case "$BUMP" in
    major) NEW_MAJOR=$((MAJOR + 1)); NEW_MINOR=0; NEW_PATCH=0 ;;
    minor) NEW_MINOR=$((MINOR + 1)); NEW_PATCH=0 ;;
    patch) NEW_PATCH=$((PATCH + 1)) ;;
    none)  ;;
  esac

  BASE_VERSION="${NEW_MAJOR}.${NEW_MINOR}.${NEW_PATCH}"
  BASE_TAG="${PREFIX}${BASE_VERSION}"
  RC_NUMBER=""

  if [ -n "$PRERELEASE" ]; then
    if [ "$PRERELEASE_IDENTIFIER" = "numbered" ]; then
      # Tag-based logic: count existing tags
      RC_PATTERN="${PREFIX}${BASE_VERSION}-${PRERELEASE}.*"
      HIGHEST_RC=$(git tag --list "$RC_PATTERN" 2>/dev/null \
        | sed "s/.*-${PRERELEASE}\.//" \
        | sed 's/-[a-f0-9]\{7,\}$//' \
        | sort -n | tail -n1 || true)
      NEXT_RC=$(( ${HIGHEST_RC:-0} + 1 ))
      RC_NUMBER="$NEXT_RC"
      NEW_VERSION="${BASE_VERSION}-${PRERELEASE}.${NEXT_RC}"
    else
      # SHA-based: use commit SHA as prerelease identifier
      SHORT_SHA=$(git rev-parse --short=7 HEAD 2>/dev/null || echo "")
      if [ -n "$SHORT_SHA" ]; then
        RC_NUMBER="$SHORT_SHA"
        NEW_VERSION="${BASE_VERSION}-${PRERELEASE}.${SHORT_SHA}"
      else
        # Fallback if SHA can't be determined
        RC_NUMBER="0"
        NEW_VERSION="${BASE_VERSION}-${PRERELEASE}.0"
      fi
    fi

    if [ "$RESOLVED_INCLUDE_SHA" = "true" ] && [ "$PRERELEASE_IDENTIFIER" = "numbered" ]; then
      # Only append SHA suffix for numbered mode (SHA mode already uses SHA as identifier)
      SHORT_SHA=$(git rev-parse --short=7 HEAD 2>/dev/null || true)
      NEW_VERSION="${NEW_VERSION}-${SHORT_SHA}"
    fi
  else
    NEW_VERSION="$BASE_VERSION"
    if [ "$RESOLVED_INCLUDE_SHA" = "true" ]; then
      SHORT_SHA=$(git rev-parse --short=7 HEAD 2>/dev/null || true)
      NEW_VERSION="${NEW_VERSION}-${SHORT_SHA}"
    fi
  fi

  NEW_TAG="${PREFIX}${NEW_VERSION}"
}