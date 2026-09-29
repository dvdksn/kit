# Development sandbox kit

A Docker Sandbox v3 kit set with a shell workload, a choice of Claude Code or Codex,
GitHub repository cloning, SSH access, Git signing, and rumdl for Markdown.

All seven component descriptors, Dockerfiles, lifecycle hooks, scripts, and
agent context files live in this repository. Builds do not fetch kit specs
from upstream repositories or use the `docker/sbx-kit-shell` image.

## Run

Use the checked-in environment file to compose the published components at
sandbox creation:

```sh
sbx env run ./sbxenv.yaml --name docs --env-arg repo=docker/docs
```

Claude is the default agent. To use Codex instead, add `--env-arg agent=codex`.
Only the selected agent mixin and its credential request are included. For
example:

```sh
sbx env run ./sbxenv.yaml --name docs-codex --env-arg repo=docker/docs --env-arg agent=codex
```

The clone is inside the sandbox at `/home/agent/workspace` (`~/workspace`),
and the shell starts there. The environment file declares no host workspace
mount. Run the command again with the same file and name to reattach.

On sbx v0.45.1, OAuth selection reads only the first OAuth provider from each
published kit artifact. Each variant of this set contains one agent and one
OAuth provider. `sbxenv.yaml` composes the selected agent and the other
components as separate artifacts.

`repo` is required and accepts `owner/repo`. To select a branch, tag, or
commit, add `--env-arg ref=main`. To check out a pull request, use
`--env-arg pr=123` instead. `ref` and `pr` are mutually exclusive.
The clone keeps full history. Retrying preserves an existing checkout of
the same repository; a different repository or unrelated files cause an
error instead of being overwritten. Use a fresh sandbox to change the
repository or initial checkout arguments.

Public repositories clone without a GitHub token. Bind a GitHub credential
on the sandbox host for private repositories, PR checkout, GitHub CLI
operations, and HTTPS pushes. The clone mixin requests proxy-managed GitHub
credentials during install and runtime; it never stores a token in the image.

Run the selected agent (`claude` or `codex`) in the shell. Use `rumdl fmt <file>` to format
Markdown and `rumdl check <file>` to lint it.
The host must have an SSH agent with a loaded key for the required SSH
capabilities. Add the appropriate public key to GitHub for authentication
and signing. Configure your Git author name and email as usual.

Claude and Codex use credentials bound through the sandbox host. Their
credential capabilities are optional; the copied hooks also support an
unbound state. These agents are configured to skip approval prompts and
rely on the sandbox boundary for isolation.

The set grants the union of its components' network and SSH permissions.
GitHub authentication is restricted to `git@github.com`; signing is
restricted to the `git` namespace. Neither mixin copies private keys into
the image.

## Source layout

| Path | Purpose |
| --- | --- |
| `sbxenv.yaml` | Selects an agent at sandbox creation and composes published component artifacts |
| `kit.yaml` | Builds either agent variant as one workload artifact |
| `kits/shell/` | Shell workload built from the DHI shell-docker template |
| `kits/claude-mixin/` | Latest Claude Code native binary, credentials, and hooks |
| `kits/codex-mixin/` | Latest Codex standalone installation, credentials, and hooks |
| `kits/github-ssh/` | GitHub SSH access and known host keys |
| `kits/git-signing/` | SSH signing permission and Git signing defaults |
| `kits/github-clone/` | Clone the requested repository into `~/workspace` |
| `kits/rumdl/` | Latest rumdl binary with verified release checksums |

The shell template follows the `shell-docker` tag. DHI base images and the upstream
agent binary downloads remain build dependencies; this repository owns
the kit definitions and recipes, not those third-party projects.
`NOTICE` records the copied examples' source revision and modifications.

## Build and publish

The `Publish kits` GitHub Actions workflow runs on pushes to `main` and
manual dispatch. It uses `GITHUB_TOKEN` with `packages: write`; no registry
password secret is needed.

1. Native AMD64 and ARM64 runners build and push the local mixins.
2. A job combines both architectures under each mixin's commit tag and
   builds the shell for both platforms together. This keeps its derived
   package declarations consistent across architectures.
3. The set builds resolve those exact commit tags and publish separate
   Claude and Codex workloads for both architectures.

The set build arg `agent=claude|codex` selects the agent mixin at build time.
Published sets cannot change their component list at sandbox creation. Use
`ghcr.io/dvdksn/kit:claude-latest` or `ghcr.io/dvdksn/kit:codex-latest` to
select an agent with a single kit reference. The `:latest` tag remains an
alias for Claude. Each variant also has a commit tag (`:claude-<sha>` or
`:codex-<sha>`); `:sha-<sha>` remains an alias for Claude.
Component tags use `:<component>-<full-commit-sha>` and
`:<component>-latest`. Use a digest when you need an immutable reference.
The frontend records component digests in the published set descriptor.

The GHCR package is public and supports anonymous pulls.

To build a component locally:

```sh
docker buildx build kits/claude-mixin \
  -f kits/claude-mixin/claude-mixin.yaml \
  --pull --no-cache -t claude-mixin:latest \
  --output type=oci,dest=/tmp/claude-layout,tar=false
kit-tck validate --layout /tmp/claude-layout latest
```

To build the set after publishing the components:

```sh
docker buildx build . -f kit.yaml \
  --build-arg revision=latest \
  --build-arg agent=codex \
  --platform linux/amd64,linux/arm64 \
  --output type=oci,dest=/tmp/kit-layout,tar=false \
  -t kit:latest
kit-tck validate --layout /tmp/kit-layout latest
```

A v3 set requires registry references, so components must be published
before the set builds. CI uses the current commit SHA instead of `latest`
to keep the component sources tied to one checkout. Each CI build fetches
latest stable program releases without cached install layers. Codex and
Claude use their official native installers; rumdl uses its latest GitHub
release and published checksum. Run the workflow again to refresh tools.
Local builds need `--pull --no-cache` for the same behavior.

No agent MCP gateway is registered automatically.

The original kit sources and Docker-derived files are Apache-2.0 licensed.
See `NOTICE` for upstream attribution and the GitHub clone source.
Third-party images and binaries retain their own licenses.
