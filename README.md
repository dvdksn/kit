# Development sandbox kits

My personal Docker Sandbox kits for a coding agent environment with a shell
workload, Claude Code, Codex,
GitHub cloning, SSH access, Git signing, rumdl for Markdown, browser tools,
Hugo Extended, and Vale.

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
Use `hugo` to build Hugo sites and `hugo server --bind 0.0.0.0` to preview them
(publish port 1313 on the sandbox host). Run `vale sync` in the project to
download configured styles, then `vale <file>` to lint prose.
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
| `kits/hugo/` | Latest stable Hugo Extended with verified release checksums |
| `kits/vale/` | Latest stable Vale prose linter with verified release checksums |
| `kits/rumdl/` | Latest rumdl binary with verified release checksums |
| `kits/github-clone/` | HTTPS clone with proxy-managed GitHub credentials |

The shell template follows the `shell-docker` tag. DHI base images and the upstream
agent binary downloads remain build dependencies; this repository owns
the kit definitions and recipes, not those third-party projects.
`NOTICE` records the copied examples' source revision and modifications.

## Published kits and development

Each component is published as a public GHCR image for AMD64 and ARM64, such as
`ghcr.io/dvdksn/kit-codex-mixin`. `sbxenv.yaml` combines the shell workload
(the base image and shell entrypoint) with mixins that add tools, credentials,
and lifecycle hooks. The environment grants the union of the kits' permissions.
The browser mixin registers `browser-use` MCP with both agents and installs
Chromium at sandbox creation; browser profiles are ephemeral and website access
follows the sandbox network policy.

The environment uses moving `:latest` tags by default. Select a published commit
build with the `revision` argument:

```sh
sbx env run ./sbxenv.yaml --name docs --env-arg repo=docker/docs \
  --env-arg revision=FULL_COMMIT_SHA
```

Use image digests when you need immutable references. Main builds publish both
commit and `latest` tags; manual feature branch builds publish commit tags only.

See [AGENTS.md](AGENTS.md) for the repository architecture, editing guidance,
and build, validation, and publishing workflow.

The original kit sources and Docker-derived files are Apache-2.0 licensed.
See `NOTICE` for upstream attribution.
Third-party images and binaries retain their own licenses.
