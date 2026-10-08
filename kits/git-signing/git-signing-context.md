# Git commit signing

Commits and tags you make are signed with the user's SSH key, through the
agent at `$SSH_AUTH_SOCK`. You do not need to pass `-S`.

- This mixin grants signatures in the `git` namespace only. Other mixins
  can grant SSH authentication too; the runtime combines those permissions.
  Signing in another namespace is unavailable.
- If `ssh-add -L` reports no agent or no identities, signing is not
  available: ask the user to reconnect the agent before committing.
- Signing a commit does not mean the user reviewed it. Say which commits
  you made.
