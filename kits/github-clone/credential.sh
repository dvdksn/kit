#!/usr/bin/env bash
# Git sees only the proxy-managed placeholder; the host proxy adds the token.
set -eu
[ "${1:-}" = get ] || exit 0
[ "${SBX_CRED_GITHUB_MODE:-none}" != none ] || exit 0
[ -n "${GH_TOKEN:-}" ] || exit 0
printf 'username=x-access-token\npassword=%s\n' "$GH_TOKEN"
