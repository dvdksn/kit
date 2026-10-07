# syntax=docker/dockerfile:1
FROM node:24.21.0-bookworm AS build
# Orca v1.4.222. Update this pin together with the descriptor version.
ARG ORCA_COMMIT=4bb6f2072b07c1f0664b809551f77754700570e4
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python3 git ca-certificates xz-utils \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git init && git remote add origin https://github.com/stablyai/orca.git \
    && git fetch --depth=1 origin "$ORCA_COMMIT" && git checkout --detach FETCH_HEAD \
    && test "$(git rev-parse HEAD)" = "$ORCA_COMMIT"
RUN corepack enable && corepack install
# Skip the desktop postinstall; build:orcad compiles its own native dependencies.
RUN --mount=type=cache,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile --ignore-scripts
ENV ORCAD_OMIT_AGENT_BROWSER=1
RUN pnpm build:orcad --out-dir /out/orcad
RUN mkdir -p /out/licenses/npm \
    && cp LICENSE /out/licenses/orca.txt \
    && cp /usr/local/LICENSE /out/licenses/node.txt \
    && find node_modules/.pnpm -type f \
       \( -iname 'license*' -o -iname 'notice*' -o -iname 'copying*' \) \
       -exec cp --parents -t /out/licenses/npm {} +

# Test-only CLI and upstream pairing/terminal acceptance test.
FROM build AS test-tools
RUN mkdir -p /test/out/cli /test/config/scripts \
    && node --input-type=module -e "import {build} from 'esbuild'; await build({entryPoints:['src/cli/index.ts'], bundle:true, platform:'node', format:'cjs', outfile:'/test/out/cli/index.js', external:['electron'], logLevel:'warning'});" \
    && cp config/scripts/runtime-serve-terminal-smoke.mjs /test/config/scripts/

FROM dhi.io/sbx-templates:shell-docker AS test
COPY --from=build /out/ /opt/orca/
COPY --chmod=755 orcad /usr/local/bin/orcad
COPY --from=test-tools /test/ /tmp/orca-smoke/
USER root
RUN ln -s /opt/orca/orcad /tmp/orca-smoke/out/orcad
USER 1000:1000
WORKDIR /home/agent/workspace
RUN --network=none orcad --orcad-smoke-load-check \
    && runtime_sha=$(cat /opt/orca/orcad/.runtime-node) \
    && "/opt/orca/runtimes/node-$runtime_sha/bin/node" \
       /tmp/orca-smoke/config/scripts/runtime-serve-terminal-smoke.mjs --target orcad

FROM scratch
COPY --from=build /out/ /opt/orca/
COPY --chmod=755 orcad /usr/local/bin/orcad
