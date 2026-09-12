-- Keymaps that don't belong to a plugin. Leader is <Space>.
-- Plugin keymaps live next to their spec in lua/devbox/plugins/.
-- Neovim 0.11+ already provides: grn rename, gra code action, grr references,
-- gri implementation, K hover, [d / ]d diagnostics, [q / ]q quickfix.

local map = vim.keymap.set

-- Escape clears the search highlight as well.
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Windows
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })
map("n", "<leader>-", "<C-w>s", { desc = "Split below" })
map("n", "<leader>|", "<C-w>v", { desc = "Split right" })

-- Buffers
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- Files
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write file" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })

-- Keep the cursor put while scrolling and searching.
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Move the selection up and down, reindenting as it goes.
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Paste over a selection without losing what was in the register.
-- (<leader>d is the debugger prefix, so plain "_d covers black-hole deletes.)
map("x", "<leader>p", [["_dP]], { desc = "Paste without clobbering the register" })

-- Stay in visual mode while shifting.
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Diagnostics
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "<leader>xl", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })

-- Terminal: one keystroke back to normal mode.
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Leave terminal mode" })
map("n", "<leader>t", "<cmd>terminal<CR>", { desc = "Terminal in this window" })

-- Python: run the current file with the project interpreter.
map("n", "<leader>rr", function()
  local py = require("devbox.python").interpreter()
  if not py then
    vim.notify("no python interpreter found — create one with: uv venv", vim.log.levels.WARN)
    return
  end
  vim.cmd("write")
  vim.cmd("botright split | resize 15 | terminal "
    .. vim.fn.shellescape(py) .. " " .. vim.fn.shellescape(vim.fn.expand("%:p")))
end, { desc = "Run this file with python" })
