# Neovim

This mixin installs the latest stable Neovim for AMD64 and ARM64, including its
runtime and bundled parsers. Builds verify the archive against the SHA256 digest
in GitHub's release metadata. It does not start services or publish ports. Run `nvim` in the sandbox, or `nvim --clean`
for stock behavior.

## Starter configuration

The image bundles `/home/agent/.config/nvim/init.lua`, owned by the agent
(uid/gid 1000). There are no install hooks or runtime file declarations.
Edit the file directly to customize a sandbox. A mounted home/config directory
can hide the bundled file; image composition can replace a file at the same
path, so this is a default for a fresh sandbox rather than a preservation hook.

This targets the standard sandbox user's config path. It does not follow custom
`XDG_CONFIG_HOME` or `NVIM_APPNAME` values, or check for a separate `init.vim`.
If you bring an `init.vim`, migrate it to `init.lua` or remove the starter Lua
file before launching Neovim; Neovim cannot use both as its user config.

The [starter config](init.lua) draws general-purpose settings from
[dvdksn/dotfiles](https://github.com/dvdksn/dotfiles/tree/main/config/nvim):

- Absolute and relative line numbers, mouse support, and five lines of scroll margin
- Smart-case search, no persistent match highlighting, and split substitution previews
- Word-aware wrapping, an 80-column guide, and display-line `j`/`k` movement
  (counts still move by physical lines)
- Four-column tabs and indentation, with project EditorConfig/filetype overrides
- Built-in completion menu settings and brief yank highlighting

It also keeps persistent undo, splits below/right, a highlighted current line,
and the built-in Habamax theme. There are no plugins or custom clipboard
settings.

A few built-in conveniences also follow
[Kickstart](https://github.com/nvim-lua/kickstart.nvim): wrapped lines retain
indentation, tabs/trailing spaces/nonbreaking spaces are visible (`> `, `·`, and `␣`), and quitting with unsaved changes offers a save confirmation.
Use `nvim --clean` to bypass the starter configuration.

## Use from your host terminal

If your sandbox runtime provides SSH access and a host alias, run Neovim
through that connection, for example:

```sh
ssh -t my-sandbox.sbx nvim
```

The `-t` allocates the terminal Neovim needs. Neovim runs in the sandbox using
its files, configuration, plugins, and tools, while your local terminal displays
it. No editor RPC listener or additional published port is needed.

SSH access and the hostname come from your runtime or separate SSH setup;
this mixin does not install an SSH server or create the alias. The existing
`github-ssh` mixin only provides outbound GitHub authentication.

You can also run `nvim` directly in an attached sandbox shell. Use
`nvim --clean` to ignore user configuration.

## remote-nvim.nvim

[remote-nvim.nvim](https://github.com/amitds1997/remote-nvim.nvim) can copy a local
configuration and manage remote sessions. Its upstream README says it is no
longer maintained. Install it on your **local** Neovim if you want to experiment.

Its SSH mode requires a reachable OpenSSH-compatible server; this mixin does
not provide one. The existing `github-ssh` mixin supplies outbound GitHub
credentials, not an inbound SSH server. The plugin also documents container
connections through DevPod, but that is not a verified Docker Sandbox transport.

If you arrange a supported transport separately, choose the plugin's option to
use an already installed remote Neovim (`/usr/local/bin/nvim`). Plugin-managed
configuration and any language servers still need their own dependencies and
network access. Plain terminal Neovim over SSH works independently of that plugin.
