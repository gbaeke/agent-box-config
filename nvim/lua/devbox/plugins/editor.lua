-- Finding things, moving around, git.

return {
  {
    "nvim-telescope/telescope.nvim",
    version = "*",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- Native sorter: compiled here, which is why the editor group installs
      -- build-essential. Without it telescope falls back to the Lua sorter.
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    keys = {
      { "<leader><space>", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Grep in project" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help tags" },
      { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
      { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Symbols in file" },
      { "<leader>fS", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", desc = "Symbols in project" },
      { "gr", "<cmd>Telescope lsp_references<CR>", desc = "References" },
      { "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search this buffer" },
    },
    opts = {
      defaults = {
        path_display = { "truncate" },
        layout_strategy = "flex",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        file_ignore_patterns = { "%.venv/", "__pycache__/", "%.git/", "%.mypy_cache/", "%.ruff_cache/" },
      },
      pickers = {
        find_files = { hidden = true },
      },
    },
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      pcall(telescope.load_extension, "fzf")
    end,
  },

  {
    -- The sidebar tree: open on the left, follows the current file. It opens
    -- by itself for `nvim` and `nvim some/dir`, not for `nvim file.py`.
    -- oil (below) is the other half: a directory as an editable buffer.
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    cmd = "Neotree",
    keys = {
      { "<C-n>", "<cmd>Neotree toggle<CR>", desc = "Toggle file tree" },
      { "<leader>ft", "<cmd>Neotree toggle<CR>", desc = "Toggle file tree" },
      { "<leader>fF", "<cmd>Neotree reveal<CR>", desc = "Reveal this file in the tree" },
      { "<leader>fG", "<cmd>Neotree git_status<CR>", desc = "Changed files in the tree" },
    },
    init = function()
      -- Opening plain `nvim`, or `nvim some/dir`, shows the tree; opening a
      -- file doesn't. Set vim.g.devbox_tree_on_start = false to stop that.
      --
      -- The arguments are read here, during startup, and not in the VimEnter
      -- callback: oil rewrites a directory argument to an oil:// URL before
      -- VimEnter runs, and isdirectory() then says no.
      local argc = vim.fn.argc()
      local wanted = argc == 0 or (argc == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1)

      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("devbox_tree_on_start", { clear = true }),
        callback = function()
          if not wanted or vim.g.devbox_tree_on_start == false then return end
          if vim.bo.filetype == "gitcommit" then return end
          -- focus, not show: with nothing else open, j/k and <CR> should just
          -- work. <C-l> (or <C-w>l) moves to the editor window.
          vim.cmd("Neotree focus")
        end,
      })
    end,
    opts = {
      close_if_last_window = true,
      popup_border_style = "rounded",
      enable_git_status = true,
      enable_diagnostics = true,
      -- No nerd font: arrows and letters, like the rest of this config.
      default_component_configs = {
        indent = { with_expanders = true, expander_collapsed = ">", expander_expanded = "v" },
        icon = { folder_closed = "▸", folder_open = "▾", folder_empty = "▹", default = " " },
        modified = { symbol = "[+]" },
        git_status = {
          symbols = {
            added = "+", modified = "~", deleted = "-", renamed = "→",
            untracked = "?", ignored = "i", unstaged = "!", staged = "*", conflict = "x",
          },
        },
      },
      window = {
        position = "left",
        width = 32,
        mappings = {
          ["<space>"] = "none",        -- leader stays the leader in here
          ["h"] = "close_node",
          ["l"] = "open",
          ["<C-n>"] = "close_window",
        },
      },
      filesystem = {
        follow_current_file = { enabled = true, leave_dirs_open = true },
        use_libuv_file_watcher = true,   -- pick up files created outside nvim
        hijack_netrw_behavior = "disabled",  -- `-` and `nvim DIR` belong to oil
        filtered_items = {
          visible = false,
          hide_dotfiles = false,
          hide_gitignored = true,
          hide_by_name = { "__pycache__", ".git", ".venv", ".mypy_cache", ".ruff_cache", ".pytest_cache" },
        },
      },
    },
  },

  {
    -- A directory is just a buffer: edit it, :w, and the filesystem follows.
    "stevearc/oil.nvim",
    version = "*",
    lazy = false,
    opts = {
      view_options = { show_hidden = true },
      keymaps = { ["q"] = "actions.close" },
    },
    keys = {
      { "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
    },
  },

  {
    "lewis6991/gitsigns.nvim",
    version = "*",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "+" }, change = { text = "~" },
        delete = { text = "_" }, topdelete = { text = "‾" }, changedelete = { text = "~" },
      },
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function map(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = "Git: " .. desc })
        end
        map("]h", function() gs.nav_hunk("next") end, "Next hunk")
        map("[h", function() gs.nav_hunk("prev") end, "Previous hunk")
        map("<leader>gp", gs.preview_hunk, "Preview hunk")
        map("<leader>gr", gs.reset_hunk, "Reset hunk")
        map("<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
        map("<leader>gd", gs.diffthis, "Diff this file")
      end,
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",           -- the master branch is in maintenance only
    build = ":TSUpdate",
    lazy = false,
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup()

      local parsers = require("devbox.parsers")
      -- Only fetch what is missing; install() compiles, so it is not free.
      local installed = ts.get_installed("parsers")
      local missing = vim.tbl_filter(function(p)
        return not vim.tbl_contains(installed, p)
      end, parsers)
      if #missing > 0 then
        ts.install(missing)
      end

      -- On the main branch, highlighting is opt-in per buffer.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("devbox_treesitter", { clear = true }),
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if lang and vim.treesitter.language.add(lang) then
            vim.treesitter.start(args.buf, lang)
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
}
