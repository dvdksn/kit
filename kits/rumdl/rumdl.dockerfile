# syntax=docker/dockerfile:1
FROM dhi.io/debian-base:trixie-dev AS build
ARG TARGETARCH
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates jq
RUN set -eu; \
    case "$TARGETARCH" in \
      amd64) target=x86_64-unknown-linux-gnu ;; \
      arm64) target=aarch64-unknown-linux-gnu ;; \
      *) echo "unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    release=$(curl -fsSL https://api.github.com/repos/rvben/rumdl/releases/latest | jq -er .tag_name); \
    archive="rumdl-${release}-${target}.tar.gz"; \
    url="https://github.com/rvben/rumdl/releases/download/${release}/${archive}"; \
    curl -fsSL "$url" -o "/tmp/$archive"; \
    curl -fsSL "$url.sha256" -o /tmp/rumdl.sha256; \
    cd /tmp; sha256sum -c rumdl.sha256; \
    mkdir -p /out/usr/local/bin; \
    tar -xzf "$archive" -C /out/usr/local/bin rumdl; \
    chown -R 0:0 /out; \
    /out/usr/local/bin/rumdl --version
FROM scratch
COPY --from=build /out /
