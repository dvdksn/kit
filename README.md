# Development sandbox kit

A Docker Sandbox v3 kit set with a shell workload, Claude Code, Codex,
GitHub repository cloning, SSH access, Git signing, and rumdl for Markdown.

All seven component descriptors, Dockerfiles, lifecycle hooks, scripts, and
agent context files live in this repository. Builds do not fetch kit specs
from upstream repositories or use the `docker/sbx-kit-shell` image.

## Run

Install a Docker Sandboxes release with Kits v3 support, then create a
sandbox with a repository argument:

```sh
sbx create --name docs --kit-arg repo=docker/docs ghcr.io/dvdksn/kit:latest
sbx run --name docs
```

The clone is inside the sandbox at `/home/agent/workspace` (`~/workspace`),
and the shell starts there. Omit the workspace path from `sbx create`:
passing `.` would mount your host checkout. A direct `sbx run` also mounts
the current directory by default, so use the two commands above.

`repo` is required and accepts `owner/repo`. To select a branch, tag, or
commit, add `--kit-arg ref=main` to the create command. To check out a pull
request, use `--kit-arg pr=123` instead. `ref` and `pr` are mutually exclusive.
The clone keeps full history. Retrying preserves an existing checkout of
the same repository; a different repository or unrelated files cause an
error instead of being overwritten. Use a fresh sandbox to change the
repository or initial checkout arguments.

Public repositories clone without a GitHub token. Bind a GitHub credential
on the sandbox host for private repositories, PR checkout, GitHub CLI
operations, and HTTPS pushes. The clone mixin requests proxy-managed GitHub
credentials during install and runtime; it never stores a token in the image.

Run `claude` or `codex` in the shell. Use `rumdl fmt <file>` to format
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
| `kit.yaml` | Composes the seven published components into one workload |
| `kits/shell/` | Shell workload built from the DHI shell-docker template |
| `kits/claude-mixin/` | Claude Code 2.1.282 binary, credentials, and hooks |
| `kits/codex-mixin/` | Codex 0.157.0 package, credentials, and hooks |
| `kits/github-ssh/` | GitHub SSH access and known host keys |
| `kits/git-signing/` | SSH signing permission and Git signing defaults |
| `kits/github-clone/` | Clone the requested repository into `~/workspace` |
| `kits/rumdl/` | rumdl 0.2.49 binary with verified release checksums |

The shell template is pinned by digest. DHI base images and the upstream
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
3. The set build resolves those exact commit tags and publishes the
   combined workload for both architectures.

The final image is `ghcr.io/dvdksn/kit:latest`. Each build also publishes
`ghcr.io/dvdksn/kit:sha-<full-commit-sha>` and the release tag `:1.1.0`.
Component tags use `:<component>-<full-commit-sha>` and
`:<component>-latest`. Use a digest when you need an immutable reference.
The frontend records component digests in the published set descriptor.

The GHCR package is public and supports anonymous pulls.

To build a component locally:

```sh
docker buildx build kits/claude-mixin \
  -f kits/claude-mixin/claude-mixin.yaml \
  -t claude-mixin:2.1.282 \
  --output type=oci,dest=/tmp/claude-layout,tar=false
kit-tck validate --layout /tmp/claude-layout 2.1.282
```

To build the set after publishing the components:

```sh
docker buildx build . -f kit.yaml \
  --build-arg revision=latest \
  --platform linux/amd64,linux/arm64 \
  --output type=oci,dest=/tmp/kit-layout,tar=false \
  -t kit:1.1.0
kit-tck validate --layout /tmp/kit-layout 1.1.0
```

A v3 set requires registry references, so components must be published
before the set builds. CI uses the current commit SHA instead of `latest`
to keep the build tied to one checkout. To update an agent, change its
`args.version.default` and verify its build; the descriptor version and
installed tool version use that same value.

The original kit sources and Docker-derived files are Apache-2.0 licensed.
See `NOTICE` for upstream attribution and the GitHub clone source.
Third-party images and binaries retain their own licenses.
