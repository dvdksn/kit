# syntax=docker/dockerfile:1
# The shell-docker template carries the platform floor (bash, the agent
# user, git, a CA store) plus a Docker engine. The workload's launch
# command is a login shell; the image config is the runtime contract.
FROM dhi.io/sbx-templates:shell-docker
USER root
RUN apt-get update && apt-get install -y --no-install-recommends build-essential && rm -rf /var/lib/apt/lists/*
RUN usermod -s /usr/bin/bash agent
USER 1000
WORKDIR /home/agent/workspace
ENV SHELL=/usr/bin/bash
ENV BROWSER=xdg-open
ENTRYPOINT ["bash"]
CMD ["-l"]
