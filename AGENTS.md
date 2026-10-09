# Repository guide

This repository contains personal Docker Sandbox kits for a coding agent
environment. The README covers the available tools and how to run the sandbox.

## Architecture

- `kits/shell/` is the workload: the base image, shell entrypoint, common CLI
  tools, and shared sandbox context. It uses the DHI `shell-docker` template.
- The other directories in `kits/` are mixins that add Claude Code, Codex,
  browser tools, GitHub access, Git signing, Hugo, Vale, rumdl, and Task to the workload.
- Each kit has a v3 descriptor (`<kit>.yaml`) declaring its capabilities and a
  content recipe (`<kit>.dockerfile`). Scripts and context files live beside them.
- `sbxenv.yaml` composes the published GHCR kits into a runnable environment.
  Its `repo` argument selects the GitHub repository to clone; `revision` selects
  the published kit tag (default: `latest`). It also binds the host GitHub token.
- `docker-bake.hcl` defines how every kit is built and tagged; the workflows in
  `.github/workflows/` call it. `tests/` covers cloning and checks that kits are
  registered consistently.

## Working on kits

To add a kit, create `kits/<name>/` with `<name>.yaml` and `<name>.dockerfile`,
then add `<name>` to `MIXINS` in `docker-bake.hcl` and a `source` entry to
`sbxenv.yaml`. `tests/test_kits.py` fails if those drift from `kits/`.

Keep tool-specific capabilities, hooks, and context in the relevant mixin.
Keep the shell workload focused on the shared environment. Update `sbxenv.yaml`
when changing the composition. The browser mixin depends on Node/npm and both
agent CLIs; keep it after the agent mixins so MCP registration follows their
configuration hooks.

Clone hooks must preserve existing working trees. GitHub SSH authentication is
limited to `git@github.com`, and SSH signing to the `git` namespace; private keys
stay on the host.

This file guides work on this repository. Sandbox agent instructions are
declared separately through the kits' `agent-context` capabilities.

## Build and validation

Run the existing checks when changing clone behavior:

```sh
python3 -m unittest discover -s tests -v
bash -n kits/github-clone/clone.sh
```

For descriptor or recipe changes, build and validate the affected kit, for example:

```sh
docker buildx build kits/claude-mixin \
  -f kits/claude-mixin/claude-mixin.yaml \
  --pull --no-cache -t claude-mixin:latest \
  --output type=oci,dest=/tmp/claude-layout,tar=false
kit-tck validate --layout /tmp/claude-layout latest
```

Builds resolve the latest stable agent and tool releases, except the pinned
Playwright MCP version and Task 3.54.0. Use `--pull --no-cache` to refresh dependencies; release
binary recipes for Hugo, Vale, rumdl, and Task verify published checksums.

Build any kit with bake, e.g. `docker buildx bake task`.

The `Publish kits` workflow runs on pushes to `main` and manual dispatch, using
`GITHUB_TOKEN` with `packages: write`. Native AMD64 and ARM64 runners build the
mixins, then a job combines their manifests and builds the shell for both
platforms together to keep derived package declarations consistent.
All builds publish full commit SHA tags; only main builds update `latest`.
Rerun the workflow to refresh tools. See `NOTICE` for copied upstream sources
and modifications.
