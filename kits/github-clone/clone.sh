#!/usr/bin/env bash
# Adapted from cdupuis/sbx-kits/github-clone for a fixed workspace and v3.
set -euo pipefail
repo=${1:?expected owner/repo}
dir=/home/agent/workspace
if [[ $# != 1 ]]; then
  echo 'github-clone: expected one owner/repo argument.' >&2
  exit 1
fi

# An unbound proxy sentinel is not a usable GitHub token. Public clones use
# unauthenticated HTTPS; bound credentials stay mediated by the host proxy.
if [[ ${SBX_CRED_GITHUB_MODE:-none} == none ]]; then
  unset GH_TOKEN
fi
export GIT_TERMINAL_PROMPT=0
url="https://github.com/$repo.git"
if [[ -d "$dir/.git" ]]; then
  origin=$(git -C "$dir" remote get-url origin)
  case "$origin" in
    "$url"|"git@github.com:$repo.git"|"ssh://git@github.com/$repo.git") ;;
    *)
      echo "github-clone: $dir already belongs to a different repository ($origin)." >&2
      exit 1 ;;
  esac
  echo "github-clone: preserving the existing working tree in $dir."
  exit 0
fi
if [[ -n $(ls -A "$dir") ]]; then
  echo "github-clone: $dir is not empty; refusing to overwrite its contents." >&2
  exit 1
fi

# Start with the default branch only. Fetch more branches/history when needed.
git clone --depth=1 -- "$url" "$dir"
