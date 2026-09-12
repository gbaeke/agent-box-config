-- devbox neovim config — a small, explicit setup aimed at Python work.
-- Managed by devbox: ./install.sh -g editor  (see ../README.md).
-- Edit the copy in the repo and re-run the installer; ~/.config/nvim is a copy.

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Show the file tree when nvim starts with no file argument. Set to false if
-- you would rather open it yourself with <C-n>.
vim.g.devbox_tree_on_start = true

require("devbox.options")
require("devbox.keymaps")

-- ---------------------------------------------------------------- lazy.nvim --
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error("could not clone lazy.nvim:\n" .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "devbox.plugins" } },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = false },          -- no background update checks
  change_detection = { notify = false },
  rocks = { enabled = false },            -- no luarocks dependency
  ui = { border = "rounded" },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "zipPlugin", "netrwPlugin", "tutor" },
    },
  },
})

-- LSP is configured with Neovim's built-in vim.lsp.config, not a plugin.
require("devbox.lsp")
