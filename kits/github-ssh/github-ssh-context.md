# GitHub over SSH

Use `git@github.com:owner/repo.git` to fetch and push through the host SSH
agent. This mixin grants authentication as `git` at `github.com`; the
separate git-signing mixin grants commit and tag signing.

GitHub host keys are stored in `~/.ssh/known_hosts`. If SSH reports a changed
host key, stop and tell the user. Do not disable host key checking.
Push only changes the user authorized.
