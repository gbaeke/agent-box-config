-- Completion and formatting. The language servers themselves are configured
-- in lua/devbox/lsp.lua with Neovim's built-in vim.lsp.config.

return {
  {
    "saghen/blink.cmp",
    version = "1.*",           -- the tags ship the prebuilt fuzzy-matcher binary
    event = { "InsertEnter", "CmdlineEnter" },
    opts = {
      keymap = {
        preset = "default",    -- <C-y> accept, <C-n>/<C-p> cycle, <C-e> cancel
        ["<Tab>"] = { "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
      },
      completion = {
        accept = { auto_brackets = { enabled = true } },
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        list = { selection = { preselect = false, auto_insert = true } },
      },
      signature = { enabled = true },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      fuzzy = {
        -- Falls back to the Lua matcher with a warning if the download failed.
        implementation = "prefer_rust_with_warning",
      },
    },
    opts_extend = { "sources.default" },
  },

  {
    "stevearc/conform.nvim",
    version = "*",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
        mode = { "n", "v" }, desc = "Format buffer" },
    },
    opts = {
      formatters_by_ft = {
        -- ruff does all three jobs, in this order: autofix, sort imports, format.
        python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
        json = { "jq" },
        -- Anything else falls back to whatever the language server offers.
      },
      default_format_opts = { lsp_format = "fallback" },
      format_on_save = function(buf)
        -- :w with a bang skips it, as does setting g:devbox_autoformat = false.
        if vim.g.devbox_autoformat == false or vim.b[buf].devbox_autoformat == false then
          return nil
        end
        return { timeout_ms = 2000, lsp_format = "fallback" }
      end,
    },
    init = function()
      vim.api.nvim_create_user_command("FormatToggle", function(args)
        if args.bang then
          vim.b.devbox_autoformat = vim.b.devbox_autoformat == false
        else
          vim.g.devbox_autoformat = vim.g.devbox_autoformat == false
        end
        vim.notify(("format on save: %s"):format(vim.g.devbox_autoformat ~= false and "on" or "off"))
      end, { bang = true, desc = "Toggle format on save (bang: this buffer only)" })
    end,
  },
}
