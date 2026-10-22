-- Plugin-free sandbox defaults drawn from dvdksn/dotfiles/config/nvim.
-- Edit freely; the kit only seeds this file once.
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.scrolloff = 5
vim.opt.mouse = "a"

-- Preview substitutions and search without leaving matches highlighted.
vim.opt.hlsearch = false
vim.opt.inccommand = "split"
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Wrap at word boundaries; show the preferred text width without enforcing it.
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.colorcolumn = "80"

-- Make invisible whitespace visible without requiring a special font.
vim.opt.list = true
vim.opt.listchars = { tab = "> ", trail = "·", nbsp = "␣" }

-- Match personal indentation defaults. EditorConfig/filetypes can override.
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = -1

vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.undofile = true
-- Offer to save rather than just failing when quitting a modified buffer.
vim.opt.confirm = true

-- A built-in theme needs no plugin downloads or special fonts.
vim.opt.termguicolors = true
vim.cmd.colorscheme("habamax")

-- Move through display lines unless a count requests physical lines.
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("SandboxYankHighlight", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
  desc = "Highlight copied text briefly",
})
