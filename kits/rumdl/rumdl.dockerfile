# syntax=docker/dockerfile:1
FROM dhi.io/debian-base:trixie-dev AS build
ARG RUMDL_VERSION
ARG TARGETARCH
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates
RUN set -eu; \
    case "$TARGETARCH" in \
      amd64) target=x86_64-unknown-linux-gnu; checksum=e208db27143592a18b26d9d42e6e76133a2dcdb8738d2ed0f8d3b44027b2d8d6 ;; \
      arm64) target=aarch64-unknown-linux-gnu; checksum=b57cfdc83f4bbe0714c4a7642464107a5c64f258d5925d67bc9b3816dbe0701a ;; \
      *) echo "unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    curl --proto '=https' --tlsv1.2 -fsSL \
      "https://github.com/rvben/rumdl/releases/download/v${RUMDL_VERSION}/rumdl-v${RUMDL_VERSION}-${target}.tar.gz" \
      -o /tmp/rumdl.tgz; \
    echo "$checksum  /tmp/rumdl.tgz" | sha256sum -c -; \
    mkdir -p /out/usr/local/bin; \
    tar -xzf /tmp/rumdl.tgz -C /out/usr/local/bin rumdl; \
    chown -R 0:0 /out; \
    test "$(/out/usr/local/bin/rumdl --version)" = "rumdl ${RUMDL_VERSION}"
FROM scratch
COPY --from=build /out /
