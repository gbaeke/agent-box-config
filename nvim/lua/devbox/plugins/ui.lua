-- Colours, statusline, keymap discovery.

return {
  {
    "folke/tokyonight.nvim",
    version = "*",
    lazy = false,
    priority = 1000,           -- load before anything that draws
    opts = {
      style = "night",
      styles = { comments = { italic = false } },
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      return {
        options = {
          theme = "tokyonight",
          globalstatus = true,
          section_separators = "",
          component_separators = "|",
          -- No nerd-font glyphs: this runs over SSH in whatever terminal you
          -- happen to have, and boxes-instead-of-icons is worse than letters.
          icons_enabled = false,
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = {
            "branch",
            { "diff", symbols = { added = "+", modified = "~", removed = "-" } },
            { "diagnostics", symbols = { error = "E", warn = "W", info = "I", hint = "H" } },
          },
          lualine_c = { { "filename", path = 1 } },
          lualine_x = {
            -- Which interpreter the LSP and <leader>rr are actually using.
            { function()
                local venv = require("devbox.python").venv_name()
                return venv and ("venv:" .. venv) or ""
              end,
              cond = function() return vim.bo.filetype == "python" end },
            { function()
                local names = {}
                for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
                  table.insert(names, c.name)
                end
                return table.concat(names, " ")
              end },
            "filetype",
          },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      }
    end,
  },

  {
    "folke/which-key.nvim",
    version = "*",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      spec = {
        { "<leader>c", group = "code" },
        { "<leader>d", group = "debug" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>r", group = "run" },
        { "<leader>x", group = "diagnostics" },
      },
    },
    keys = {
      { "<leader>?", function() require("which-key").show({ global = true }) end, desc = "All keymaps" },
    },
  },
}
