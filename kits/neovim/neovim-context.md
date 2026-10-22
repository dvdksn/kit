## Neovim

Stock `nvim` is installed with its runtime. Use `nvim --clean` to ignore user
configuration, or `nvim <file>` to edit normally. A small plugin-free starter `init.lua` is seeded at creation only when no
`init.lua` or `init.vim` exists. Preserve user edits. No editor server or port
publication is configured automatically.

Run Neovim in an attached sandbox shell. If the host has SSH access to the
sandbox, `ssh -t <sandbox-host> nvim` provides a terminal UI without an editor
RPC listener. SSH access is provided separately, not by this mixin.

See https://github.com/dvdksn/kit/tree/main/kits/neovim for connection guidance.
