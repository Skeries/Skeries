#!/usr/bin/env bash
# check_actions_token.sh
# Safely test a fine-grained GitHub token for permission to read repository Actions variables.
# Usage: ./scripts/check_actions_token.sh
# You'll be prompted to paste the token (it will not be echoed).

set -euo pipefail

REPO_OWNER=${REPO_OWNER:-Skeries}
REPO_NAME=${REPO_NAME:-Skeries}
API="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/actions/variables?per_page=1"

read -s -p "Paste fine-grained token (will not be shown): " TOKEN
echo

TMPRESP=$(mktemp)
HTTP_CODE=$(curl -sS -o "$TMPRESP" -w "%{http_code}" \
  -H "Authorization: token $TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "$API")
BODY=$(cat "$TMPRESP")
rm -f "$TMPRESP"

if [[ "$HTTP_CODE" == "200" ]]; then
  echo "OK: token can read repository Actions variables (HTTP 200)."
  echo "$BODY" | jq .
  exit 0
fi

if [[ "$HTTP_CODE" == "403" ]]; then
  echo "403: token is not authorized to read repository Actions variables." >&2
  echo " - Check that the token is a fine-grained token scoped to the repository ${REPO_OWNER}/${REPO_NAME}." >&2
  echo " - Ensure the token's Actions permission allows reading repository variables/secrets." >&2
  echo " - If your organization enforces SSO, authorize the token for the organization." >&2
  echo "Response body:" >&2
  echo "$BODY" | jq . >&2 || echo "$BODY" >&2
  exit 2
fi

# Other responses
echo "$HTTP_CODE: unexpected response" >&2
echo "$BODY" | jq . || echo "$BODY" >&2
exit 3
