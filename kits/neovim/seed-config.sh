#!/bin/sh
# Run as the sandbox user. Preserve existing configs, including dangling links.
set -eu
config="${XDG_CONFIG_HOME:-$HOME/.config}/${NVIM_APPNAME:-nvim}"
for init in "$config/init.lua" "$config/init.vim"; do
    if [ -e "$init" ] || [ -L "$init" ]; then
        exit 0
    fi
done
mkdir -p "$config"
cp -n /usr/local/share/neovim-kit/init.lua "$config/init.lua"
