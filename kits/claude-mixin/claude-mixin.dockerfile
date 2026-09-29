# syntax=docker/dockerfile:1
FROM dhi.io/debian-base:trixie-dev AS build
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates
RUN curl -fsSL https://claude.ai/install.sh -o /tmp/install-claude.sh \
 && bash /tmp/install-claude.sh latest \
 && mkdir -p /out/usr/local/bin \
 && cp -L /root/.local/bin/claude /out/usr/local/bin/claude \
 && chmod 0755 /out/usr/local/bin/claude \
 && /out/usr/local/bin/claude --version

FROM scratch
COPY --from=build /out /
