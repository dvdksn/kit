# syntax=docker/dockerfile:1
FROM dhi.io/debian-base:trixie-dev AS build
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates
# Codex detects standalone installs under CODEX_HOME/packages/standalone/releases.
ENV CODEX_HOME=/home/agent/.codex
ENV CODEX_INSTALL_DIR=/home/agent/.local/bin
RUN <<'INSTALL'
set -eu
curl -fsSL https://chatgpt.com/codex/install.sh -o /tmp/install-codex.sh
CODEX_NON_INTERACTIVE=true sh /tmp/install-codex.sh
"$CODEX_INSTALL_DIR/codex" --version
mkdir -p /out/home/agent/.codex /out/home/agent/.local /out/usr/local/bin
cp -a "$CODEX_HOME/packages" /out/home/agent/.codex/packages
cp -a "$CODEX_INSTALL_DIR" /out/home/agent/.local/bin
ln -s /home/agent/.local/bin/codex /out/usr/local/bin/codex
ln -s /home/agent/.codex/packages/standalone/current/bin/codex-code-mode-host /out/usr/local/bin/codex-code-mode-host
chown -R 1000:1000 /out/home/agent
INSTALL

# Keep shell preferences separate from additive image environment variables.
RUN mkdir -p /out/etc/profile.d && cat > /out/etc/profile.d/codex-env.sh <<'PROFILE'
export CODEX_HOME=/home/agent/.codex
export IS_SANDBOX=1
export GIT_TERMINAL_PROMPT=0
PROFILE

FROM scratch
COPY --from=build /out /
