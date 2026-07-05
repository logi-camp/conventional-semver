#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ERRORS=()
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENTRYPOINT="${SCRIPT_DIR}/../entrypoint.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

# shellcheck source=lib/helpers.sh
source "${SCRIPT_DIR}/lib/helpers.sh"

echo -e "\n${BOLD}conventional-semver test suite${NC}\n"

# shellcheck source=cases/no_tags.sh
source "${SCRIPT_DIR}/cases/no_tags.sh"
# shellcheck source=cases/bump_feat.sh
source "${SCRIPT_DIR}/cases/bump_feat.sh"
# shellcheck source=cases/bump_fix.sh
source "${SCRIPT_DIR}/cases/bump_fix.sh"
# shellcheck source=cases/bump_perf.sh
source "${SCRIPT_DIR}/cases/bump_perf.sh"
# shellcheck source=cases/bump_breaking.sh
source "${SCRIPT_DIR}/cases/bump_breaking.sh"
# shellcheck source=cases/priority.sh
source "${SCRIPT_DIR}/cases/priority.sh"
# shellcheck source=cases/default_bump.sh
source "${SCRIPT_DIR}/cases/default_bump.sh"
# shellcheck source=cases/version_arithmetic.sh
source "${SCRIPT_DIR}/cases/version_arithmetic.sh"
# shellcheck source=cases/prefix.sh
source "${SCRIPT_DIR}/cases/prefix.sh"
# shellcheck source=cases/outputs.sh
source "${SCRIPT_DIR}/cases/outputs.sh"
# shellcheck source=cases/changelog.sh
source "${SCRIPT_DIR}/cases/changelog.sh"
# shellcheck source=cases/validation.sh
source "${SCRIPT_DIR}/cases/validation.sh"
# shellcheck source=cases/prerelease.sh
source "${SCRIPT_DIR}/cases/prerelease.sh"

echo ""
echo -e "${BOLD}Results: ${GREEN}${PASS} passed${NC}  ${RED}${FAIL} failed${NC}"

if [ "${#ERRORS[@]}" -gt 0 ]; then
  echo -e "\nFailed tests:"
  for e in "${ERRORS[@]}"; do
    echo -e "  ${RED}✗${NC} $e"
  done
  exit 1
fi
