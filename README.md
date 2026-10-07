# Development sandbox kits

A Docker Sandbox environment with a shell workload, Claude Code, Codex,
GitHub cloning, SSH access, Git signing, and rumdl for Markdown.

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

For a project-oriented launcher with automatic conversation persistence, use
[sup](https://github.com/dvdksn/sup). It manages the native `sbx mount` attachment and selected agent state before
agent use. Running this environment directly leaves history in
the sandbox unless you explicitly set up persistence.

On sbx v0.45.1, OAuth selection reads only the first OAuth provider from each
published kit artifact. `sbxenv.yaml` composes Claude and Codex as separate
artifacts, so each agent's host OAuth credential can be selected. The GitHub
and Markdown mixins are published as one tools set because seven individual
kits exceed Docker's container-label size limit for the composition lock.

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
| `kits/github-ssh/` | GitHub SSH access and known host keys |
| `kits/git-signing/` | Runtime Git identity, SSH signing permission, and signing defaults |
| `kits/rumdl/` | Latest rumdl binary with verified release checksums |
| `kits/github-clone/` | HTTPS clone with proxy-managed GitHub credentials |
| `kits/orcad/` | Optional Orca Node server with its own Node runtime |
| `kits/tools/` | Published set of GitHub and Markdown mixins |

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
3. A job combines the four non-agent mixins into one tools artifact.

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

The agent and rumdl builds fetch the latest stable program releases without cached
install layers. Codex and Claude use their official native installers; rumdl
uses its latest GitHub release and published checksum. Run the workflow again
to refresh tools.
Local builds need `--pull --no-cache` for the same behavior.

## Orca

Add the optional server mixin to your environment's `kits` list:

```yaml
  - source: ghcr.io/dvdksn/kit-orcad:latest
```

It installs `orcad` and its own Node runtime, built from pinned Orca v1.4.222
sources. Start it as the sandbox's `agent` user. From the host, this command
starts the server and keeps an SSH tunnel open:

```sh
ssh -L 6800:127.0.0.1:6800 docker-docs.sbx 'orcad --port 6800 --json'
```

Use the `pairing.url` in its ready JSON to register the environment on the host:

```sh
orca environment add --name docker-docs --pairing-code 'orca://pair?code=...'
```

Keep the SSH command running while using the environment. The server listens
on sandbox loopback; the mixin requests no published ports. State stays in the
sandbox under `~/.orca`. The optional browser binary is omitted.

The `Test orcad` workflow builds on native amd64 and arm64 runners. It pairs a
client, adds a temporary repo, creates a worktree, and runs a terminal command
in the shell base image. Run the same test locally on your native architecture:

```sh
docker buildx build kits/orcad -f kits/orcad/orcad.dockerfile --target test
```

No agent MCP gateway is registered automatically.

The original kit sources and Docker-derived files are Apache-2.0 licensed.
See `NOTICE` for upstream attribution.
Third-party images and binaries retain their own licenses.

## Agent context and history

The shell provides a brief environment description and the project location.
The signing mixin explains its Git-only SSH signing constraint. Other mixins
install and configure tools without adding routine agent instructions.

History persistence belongs to the host launcher. There is no history kit or
installed history command. Sup uses the native `sbx mount` command to attach a
per-project host directory, then connects selected agent paths before use.
Running the kit directly keeps conversations inside the sandbox by default.

```sh
python3 -m unittest discover -s tests -v
bash -n kits/github-clone/clone.sh
```
