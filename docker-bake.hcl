# Builds and publishes every kit. The publish workflow drives this file:
#
#   docker buildx bake mixins --push   # per-architecture mixin images
#   docker buildx bake shell --push    # multi-platform shell workload
#
# Adding a kit under kits/<name>/ (descriptor kits/<name>/<name>.yaml) only
# needs the name added to MIXINS; tests/test_kits.py checks the list against
# the directory and sbxenv.yaml.

variable "REGISTRY" {
  default = "ghcr.io/dvdksn/kit"
}

# Tag for this build, normally the full commit SHA.
variable "TAG" {
  default = "dev"
}

# Also tag the shell as :latest (main builds only).
variable "LATEST" {
  default = false
}

# Build mixins for this architecture only and suffix their tags with it
# (e.g. "amd64"). Empty builds for the native platform with the plain tag.
variable "ARCH" {
  default = ""
}

variable "MIXINS" {
  default = [
    "claude-mixin",
    "codex-mixin",
    "browser-mixin",
    "github-ssh",
    "git-signing",
    "github-clone",
    "hugo",
    "vale",
    "task",
    "rumdl",
  ]
}

group "default" {
  targets = ["shell", "mixins"]
}

group "mixins" {
  targets = MIXINS
}

target "_kit" {
  pull     = true
  no-cache = true
  attest   = ["type=provenance,disabled=true"]
}

target "mixin" {
  inherits   = ["_kit"]
  name       = kit
  matrix     = { kit = MIXINS }
  context    = "kits/${kit}"
  dockerfile = "${kit}.yaml"
  platforms  = ARCH != "" ? ["linux/${ARCH}"] : []
  tags       = ["${REGISTRY}-${kit}:${TAG}${ARCH != "" ? "-${ARCH}" : ""}"]
}

# Built for both platforms in one invocation so the derived package
# declarations stay consistent across architectures.
target "shell" {
  inherits   = ["_kit"]
  context    = "kits/shell"
  dockerfile = "shell.yaml"
  platforms  = ["linux/amd64", "linux/arm64"]
  tags = concat(
    ["${REGISTRY}-shell:${TAG}"],
    LATEST ? ["${REGISTRY}-shell:latest"] : [],
  )
}
