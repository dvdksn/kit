# Neovim

Latest stable Neovim for AMD64 and ARM64, with its full runtime and a small,
plugin-free [Lua config](init.lua) based on
[dvdksn/dotfiles](https://github.com/dvdksn/dotfiles/tree/main/config/nvim).
Release archives are verified against GitHub's SHA256 metadata.

Run `nvim` in the sandbox, or `nvim --clean` for stock behavior. If your sandbox
has SSH access, you can also run it from your host terminal:

```sh
ssh -t my-sandbox.sbx nvim
```

The config is bundled at `/home/agent/.config/nvim/init.lua`, owned by the agent
and ready to edit. A mounted home/config directory can hide it. This kit does
not set up SSH, start an editor server, or publish ports.
