# syntax=docker/dockerfile:1
# The shell-docker template carries the platform floor (bash, the agent
# user, git, a CA store) plus a Docker engine. The workload's launch
# command is a login shell; the image config is the runtime contract.
FROM dhi.io/sbx-templates:shell-docker@sha256:510ee44758b5395087400f02237390c030eea0846dd1c20ab105ace05a92b715
ENTRYPOINT ["bash"]
CMD ["-l"]
