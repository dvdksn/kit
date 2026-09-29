# GitHub repository

The requested repository is cloned into `/home/agent/workspace` before the
shell starts. Use that directory as the working copy. An optional ref or
pull request is checked out during creation, with full history available.

Public repositories can be cloned without a GitHub token. Private access,
GitHub API operations, and HTTPS pushes use the host's GitHub credential
through the sandbox proxy. The real token is not stored in the image.

The GitHub SSH mixin also supports SSH remotes. Signing is supplied by the
separate Git signing mixin. Push only changes the user authorized.
