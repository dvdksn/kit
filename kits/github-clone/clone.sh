#!/usr/bin/env bash
# Adapted from cdupuis/sbx-kits/github-clone for a fixed workspace and v3.
set -euo pipefail
repo=${1:?expected owner/repo}
ref=${2:-}
pr=${3:-}
dir=/home/agent/workspace

if [[ -n "$ref" && -n "$pr" ]]; then
  echo 'github-clone: ref and pr are mutually exclusive.' >&2
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
  if [[ "$origin" != "$url" ]]; then
    echo "github-clone: $dir already belongs to a different repository ($origin)." >&2
    exit 1
  fi
  echo "github-clone: preserving the existing working tree in $dir."
  exit 0
fi
if [[ -n $(ls -A "$dir") ]]; then
  echo "github-clone: $dir is not empty; refusing to overwrite its contents." >&2
  exit 1
fi

# Keep full history for PR comparisons and commit-SHA checkouts. A failed
# clone is never followed by deletion of an existing workspace.
git clone -- "$url" "$dir"
if [[ -n "$ref" ]]; then
  git -C "$dir" checkout "$ref"
elif [[ -n "$pr" ]]; then
  git -C "$dir" fetch origin "refs/pull/$pr/head:refs/remotes/origin/pr/$pr"
  git -C "$dir" checkout --detach "refs/remotes/origin/pr/$pr"
fi
