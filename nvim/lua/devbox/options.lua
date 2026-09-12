-- Editor behaviour. Nothing here needs a plugin.

local o = vim.opt

o.number = true
o.relativenumber = true
o.cursorline = true
o.signcolumn = "yes"          -- no text shifting when diagnostics appear
o.scrolloff = 8
o.sidescrolloff = 8
o.wrap = false
o.termguicolors = true
o.mouse = "a"
o.showmode = false            -- lualine already shows it
o.splitright = true
o.splitbelow = true
o.confirm = true              -- ask instead of failing on :q with changes

-- Indentation: 4 spaces, the Python default. Two-space filetypes are set below.
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.softtabstop = 4
o.shiftround = true
o.breakindent = true

-- Search
o.ignorecase = true
o.smartcase = true
o.inccommand = "split"        -- live preview for :%s/

-- Files and undo: no swap, but undo survives a reboot.
o.swapfile = false
o.backup = false
o.undofile = true
o.updatetime = 250            -- also how fast CursorHold (diagnostics, highlights) fires
o.timeoutlen = 400

-- Completion menu behaviour, shared by blink.cmp and the built-in one.
o.completeopt = { "menu", "menuone", "noselect", "popup" }
o.pumheight = 12

o.list = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
o.fillchars = { eob = " " }

-- ruff's default line length. Visible, not enforced.
o.colorcolumn = "88"

-- Yanking over SSH lands in the *local* clipboard via OSC 52, which Neovim
-- selects automatically when $SSH_TTY is set and no clipboard tool exists.
o.clipboard = "unnamedplus"

-- Python: pin the provider to the system interpreter when there is one. A box
-- whose only pythons live in uv venvs has none, and an empty value here is
-- worse than no value at all.
local python3 = vim.fn.exepath("python3")
if python3 ~= "" then
  vim.g.python3_host_prog = python3
end
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0

local group = vim.api.nvim_create_augroup("devbox_options", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "lua", "json", "jsonc", "yaml", "toml", "html", "css", "javascript", "typescript" },
  callback = function()
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
    vim.bo.softtabstop = 2
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "markdown", "gitcommit", "text" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.colorcolumn = ""
  end,
})

-- Briefly highlight whatever was just yanked.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})

-- Reopen a file on the line you left it.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
