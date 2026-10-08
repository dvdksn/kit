# Development sandbox kits

A Docker Sandbox environment with a shell workload, Claude Code, Codex,
GitHub cloning, SSH access, Git signing, rumdl for Markdown, and browser tools.

All component descriptors, Dockerfiles, lifecycle hooks, scripts, and
agent context files live in this repository. Builds do not fetch kit specs
from upstream repositories or use the `docker/sbx-kit-shell` image.

## Run

Use the checked-in environment file to compose the published components at
sandbox creation:

```sh
sbx env run ./sbxenv.yaml --name docs --env-arg repo=docker/docs
```

Without `--name`, the sandbox is named `dev`. Use a distinct name for each
repository you work on.

The kit clones the selected GitHub repository **inside** the sandbox at
`/home/agent/workspace` (`~/workspace`), where the shell starts. It preserves an
existing working tree instead of recloning or resetting it. The only clone input
is `repo`: creation clones the default branch with `--depth=1`. Git HTTPS auth
uses upstream's `gh auth git-credential` helper. The separate clone script holds
the retry checks that preserve existing work. Use
`git fetch --unshallow` inside the sandbox when you need older history.
The environment does not mount a host repository. Run it again with the same
file, name, and arguments to reattach.

For a project-oriented launcher, use [sup](https://github.com/dvdksn/sup).

Use SBX v0.48 or newer. `sbxenv.yaml` composes Claude and Codex as separate
artifacts so each agent can use its host OAuth credentials.

Run `claude` or `codex` in the shell. Use `rumdl fmt <file>` to format
Markdown and `rumdl check <file>` to lint it.
The host must have an SSH agent with a loaded key for the required SSH
capabilities. Add the appropriate public key to GitHub for authentication
and signing. The signing mixin requests `git-identity@1`, so the runtime
is responsible for supplying your Git author name and email as sandbox
defaults. Repository-local identity settings still take precedence. In a live
check, SBX v0.45.1 accepted the required declaration but left both defaults
unset despite a configured host identity. That runtime does not yet provide
the requested behavior; configure the guest identity until runtime support
is available.

Claude and Codex use credentials bound through the sandbox host. Their
credential capabilities are optional; the copied hooks also support an
unbound state. These agents are configured to skip approval prompts and
rely on the sandbox boundary for isolation.

The environment grants the union of its kits' network and SSH permissions.
GitHub authentication is restricted to `git@github.com`; signing is
restricted to the `git` namespace. Neither mixin copies private keys into
the image.

## Source layout

| Path | Purpose |
| --- | --- |
| `sbxenv.yaml` | Composes the published kits at sandbox creation |
| `kits/shell/` | Shell workload built from the DHI shell-docker template |
| `kits/claude-mixin/` | Latest Claude Code native binary, credentials, and hooks |
| `kits/codex-mixin/` | Latest Codex standalone installation, credentials, and hooks |
| `kits/browser-mixin/` | Pinned Playwright MCP and Chromium for both agents |
| `kits/github-ssh/` | GitHub SSH access and known host keys |
| `kits/git-signing/` | Runtime Git identity, SSH signing permission, and signing defaults |
| `kits/rumdl/` | Latest rumdl binary with verified release checksums |
| `kits/github-clone/` | HTTPS clone with proxy-managed GitHub credentials |

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

Each component has its own GHCR image, such as
`ghcr.io/dvdksn/kit-codex-mixin`. The distinct image names let `sbx`
compose the kits without a name collision. All component sources remain in
this GitHub repository.

Component images have `:<full-commit-sha>` and `:latest` tags. Use a digest
when you need an immutable reference. The environment file uses the moving
`:latest` tags, with a `revision` argument to select a commit build:

```sh
sbx env run ./sbxenv.yaml --name docs --env-arg repo=docker/docs \
  --env-arg revision=FULL_COMMIT_SHA
```

Manual builds on feature branches publish commit tags only; they do not move
`:latest`. Main builds publish both. Images previously published under `ghcr.io/dvdksn/kit`
remain in GHCR but are no longer updated.

The GHCR packages are public and support anonymous pulls.

To build a component locally:

```sh
docker buildx build kits/claude-mixin \
  -f kits/claude-mixin/claude-mixin.yaml \
  --pull --no-cache -t claude-mixin:latest \
  --output type=oci,dest=/tmp/claude-layout,tar=false
kit-tck validate --layout /tmp/claude-layout latest
```

Each CI build fetches the latest stable program releases without cached
install layers. Codex and Claude use their official native installers; rumdl
uses its latest GitHub release and published checksum. Run the workflow again
to refresh tools.
Local builds need `--pull --no-cache` for the same behavior.

The browser mixin registers the local `browser-use` MCP server with Claude
(user scope) and Codex. Ask either agent to use browser-use to open a website.
Each server uses an isolated ephemeral profile and a separate output directory
under `/tmp`. Chromium and its system dependencies are installed at sandbox
creation. Website access follows your sandbox network policy.
The mixin expects Node/npm and both agent CLIs from the composed environment;
keep it after the agent mixins so registration follows their config setup.
No agent MCP gateway is registered automatically.

The original kit sources and Docker-derived files are Apache-2.0 licensed.
See `NOTICE` for upstream attribution.
Third-party images and binaries retain their own licenses.

## Agent context

The shell provides a brief environment description and the project location.
The signing mixin explains its Git-only SSH signing constraint. Other mixins
install and configure tools without adding routine agent instructions.

```sh
python3 -m unittest discover -s tests -v
bash -n kits/github-clone/clone.sh
```
