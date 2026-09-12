-- Treesitter parsers to compile. Kept in its own module so install.sh can
-- compile them headlessly at install time:
--   nvim --headless -c 'lua require("nvim-treesitter").install(require("devbox.parsers")):wait(600000)' -c qa
return {
  "python", "lua", "bash", "json", "yaml", "toml",
  "markdown", "markdown_inline", "dockerfile", "sql", "regex", "html", "css",
}
