# syntax=docker/dockerfile:1
FROM dhi.io/debian-base:trixie-dev AS build
ARG TARGETARCH
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates
# Resolve latest stable at build time, as rumdl does.
# Use the public latest-release redirect to avoid GitHub API rate limits.
# Verify the archive against the same release's published checksum list before extraction.
RUN set -eu; \
    case "$TARGETARCH" in \
      amd64) target=linux-amd64 ;; \
      arm64) target=linux-arm64 ;; \
      *) echo "unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    latest=$(curl --proto '=https' --tlsv1.2 -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/gohugoio/hugo/releases/latest); \
    release="${latest##*/}"; \
    case "$latest" in https://github.com/gohugoio/hugo/releases/tag/v*) ;; *) echo "unexpected latest release URL: $latest" >&2; exit 1 ;; esac; \
    version="${release#v}"; \
    archive="hugo_extended_${version}_${target}.tar.gz"; \
    url="https://github.com/gohugoio/hugo/releases/download/$release"; \
    curl --proto '=https' --tlsv1.2 -fsSL "$url/$archive" -o "/tmp/$archive"; \
    curl --proto '=https' --tlsv1.2 -fsSL "$url/hugo_${version}_checksums.txt" -o /tmp/checksums.txt; \
    cd /tmp; \
    awk -v archive="$archive" '$2 == archive || $2 == "*" archive {print; found=1} END {if (!found) exit 1}' checksums.txt > selected.sha256; \
    sha256sum -c selected.sha256; \
    mkdir -p /out/usr/local/bin; \
    tar -xzf "$archive" -C /out/usr/local/bin hugo; \
    chown -R 0:0 /out; \
    /out/usr/local/bin/hugo version
FROM scratch
COPY --from=build /out /
