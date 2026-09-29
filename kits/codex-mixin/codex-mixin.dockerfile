# syntax=docker/dockerfile:1
FROM dhi.io/debian-base:trixie-dev AS build
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates
# Use the official standalone installer, including its native companion files.
RUN curl -fsSL https://chatgpt.com/codex/install.sh -o /tmp/install-codex.sh \
 && CODEX_NON_INTERACTIVE=true sh /tmp/install-codex.sh \
 && mkdir -p /out/opt /out/usr/local/bin \
 && cp -a "$(readlink -f /root/.codex/packages/standalone/current)" /out/opt/codex \
 && ln -s /opt/codex/bin/codex /out/usr/local/bin/codex \
 && ln -s /opt/codex/bin/codex-code-mode-host /out/usr/local/bin/codex-code-mode-host \
 && chown -R 0:0 /out \
 && /out/opt/codex/bin/codex --version

# Keep shell preferences separate from additive image environment variables.
RUN mkdir -p /out/etc/profile.d && cat > /out/etc/profile.d/codex-env.sh <<'PROFILE'
export BROWSER=xdg-open
export CODEX_HOME=/home/agent/.codex
export IS_SANDBOX=1
export GIT_TERMINAL_PROMPT=0
PROFILE

FROM scratch
COPY --from=build /out /
