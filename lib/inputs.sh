parse_inputs() {
  PREFIX="${INPUT_PREFIX:-v}"
  DEFAULT_BUMP="${INPUT_DEFAULT_BUMP:-patch}"
  INITIAL_VERSION="${INPUT_INITIAL_VERSION:-0.0.0}"
  PRERELEASE="${INPUT_PRERELEASE:-}"
  PRERELEASE_IDENTIFIER="${INPUT_PRERELEASE_IDENTIFIER:-numbered}"
  INCLUDE_SHA="${INPUT_INCLUDE_SHA:-auto}"

  case "$DEFAULT_BUMP" in
    major|minor|patch|none) ;;
    *)
      echo "::error::Invalid default_bump: '$DEFAULT_BUMP'. Must be one of: major, minor, patch, none" >&2
      exit 1
      ;;
  esac

  if [ -n "$PRERELEASE" ]; then
    if ! echo "$PRERELEASE" | grep -qE '^[a-zA-Z0-9]+$'; then
      echo "::error::Invalid prerelease: '$PRERELEASE'. Must be alphanumeric (e.g. rc, alpha, beta)" >&2
      exit 1
    fi
  fi

  case "$PRERELEASE_IDENTIFIER" in
    numbered|sha) ;;
    *)
      echo "::error::Invalid prerelease_identifier: '$PRERELEASE_IDENTIFIER'. Must be one of: numbered, sha" >&2
      exit 1
      ;;
  esac

  case "$INCLUDE_SHA" in
    auto|true|false) ;;
    *)
      echo "::error::Invalid include_sha: '$INCLUDE_SHA'. Must be one of: auto, true, false" >&2
      exit 1
      ;;
  esac

  RESOLVED_INCLUDE_SHA="$INCLUDE_SHA"
  if [ "$INCLUDE_SHA" = "auto" ]; then
    if [ -n "$PRERELEASE" ]; then
      RESOLVED_INCLUDE_SHA="true"
    else
      RESOLVED_INCLUDE_SHA="false"
    fi
  fi
}