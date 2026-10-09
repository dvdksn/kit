# Task mixin

Local variant of [docker/sbx-kits-contrib/task](https://github.com/docker/sbx-kits-contrib/tree/2159318f7d7e362b38ab60234b6bf91c113a08b9/task).
Ships Task 3.54.0 at `/usr/local/bin/task` for Linux AMD64 and ARM64.
The build verifies the upstream per-architecture SHA256 and installed version,
and normalizes binary ownership to root. No sandbox capabilities are requested.
Remote Taskfile includes and commands follow the composed network policy.

The default `sbxenv.yaml` includes the published `ghcr.io/dvdksn/kit-task` image.
Run `task --list` in a project to list tasks, or `task <name>` to run one.

To build and check locally:

```sh
docker buildx build kits/task -f kits/task/task.yaml \
  --output type=oci,dest=/tmp/task-layout,tar=false -t task:3.54.0
kit-tck validate --layout /tmp/task-layout 3.54.0
sbx run ./kits/shell --kit ./kits/task --detached --name task-check .
sbx exec task-check task --version
```

To update the pin, change the descriptor's default and pattern, `TASK_VERSION`
and both SHA256 values in the recipe, and the version documented here together.
The DHI build base follows this repository's other binary mixins; the final
image is a scratch overlay containing only the binary and kit metadata.
