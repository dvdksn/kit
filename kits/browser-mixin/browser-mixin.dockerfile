# syntax=docker/dockerfile:1
# npm content ships as an overlay; apt dependencies need the composed base.
FROM dhi.io/sbx-templates:shell-docker AS build
USER root
RUN npm install --global --prefix /opt/browser-use @playwright/mcp@0.0.80 playwright@1.63.0-alpha-2026-08-31 \
    && /opt/browser-use/bin/playwright-mcp --version \
    && chown -R 0:0 /opt/browser-use \
    && mkdir -p /out/usr/local/bin \
    && ln -s /opt/browser-use/bin/playwright /out/usr/local/bin/playwright \
    && ln -s /opt/browser-use/bin/playwright-mcp /out/usr/local/bin/playwright-mcp

FROM scratch
COPY --from=build /opt/browser-use /opt/browser-use
COPY --chmod=0755 browser-use-mcp /usr/local/bin/browser-use-mcp
COPY --from=build /out /
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright
