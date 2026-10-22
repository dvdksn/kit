# syntax=docker/dockerfile:1
FROM dhi.io/debian-base:trixie-dev AS build
ARG TARGETARCH
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates jq
# GitHub publishes SHA256 digests in release asset metadata. Resolve the release
# once so the URL and digest always describe the same asset.
RUN set -eu; \
    case "$TARGETARCH" in \
      amd64) arch=x86_64 ;; \
      arm64) arch=arm64 ;; \
      *) echo "unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    archive="nvim-linux-$arch.tar.gz"; \
    curl --proto '=https' --tlsv1.2 -sSL --fail-with-body https://api.github.com/repos/neovim/neovim/releases/latest -o /tmp/release.json || { cat /tmp/release.json >&2; exit 1; }; \
    url=$(jq -er --arg name "$archive" '.assets[] | select(.name == $name) | .browser_download_url' /tmp/release.json); \
    digest=$(jq -er --arg name "$archive" '.assets[] | select(.name == $name) | .digest | select(test("^sha256:[0-9a-f]{64}$"))' /tmp/release.json); \
    curl --proto '=https' --tlsv1.2 -sSL --fail-with-body "$url" -o /tmp/nvim.tar.gz || { cat /tmp/nvim.tar.gz >&2; exit 1; }; \
    echo "${digest#sha256:}  /tmp/nvim.tar.gz" | sha256sum -c -; \
    mkdir -p /out/usr/local; \
    tar -xzf /tmp/nvim.tar.gz -C /out/usr/local --strip-components=1; \
    chown -R 0:0 /out; \
    /out/usr/local/bin/nvim --version; \
    /out/usr/local/bin/nvim --clean --headless '+lua assert(vim.fn.isdirectory(vim.env.VIMRUNTIME) == 1)' +quit
# Include bin, lib, and share: Neovim needs its bundled parsers and runtime.
FROM scratch
COPY --from=build /out /
COPY --chown=1000:1000 --chmod=0644 init.lua /home/agent/.config/nvim/init.lua
