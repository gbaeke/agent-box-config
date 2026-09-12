-- Language servers, configured with Neovim's built-in vim.lsp.config.
--
-- No nvim-lspconfig: on 0.11+ a server definition is a table of cmd, filetypes
-- and root markers, and writing the two Python servers out by hand is shorter
-- than depending on a plugin that carries three hundred of them.
--
-- Python is split in two, which is how both tools are meant to be used:
--   basedpyright  types, completion, hover, go-to-definition, inlay hints
--   ruff          lint diagnostics and fixes (formatting goes through conform)

local python = require("devbox.python")

-- --------------------------------------------------------------- diagnostics --
vim.diagnostic.config({
  severity_sort = true,
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  virtual_text = {
    spacing = 2,
    prefix = "●",
    source = "if_many",
    severity = { min = vim.diagnostic.severity.WARN },
  },
  float = { border = "rounded", source = "if_many" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    },
  },
})

-- ------------------------------------------------------------------- servers --
vim.lsp.config("basedpyright", {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" },
  settings = {
    basedpyright = {
      -- ruff organises imports; two tools fighting over them is worse than one.
      disableOrganizeImports = true,
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        autoImportCompletions = true,
        diagnosticMode = "openFilesOnly",
        -- basedpyright defaults to "recommended", which is strict enough to
        -- bury an ordinary codebase in hints. "standard" is pyright's default.
        typeCheckingMode = "standard",
        inlayHints = {
          variableTypes = true,
          callArgumentNames = true,
          functionReturnTypes = true,
          genericTypes = false,
        },
      },
    },
  },
  before_init = function(_, config)
    -- Point the server at the project's virtualenv, not the system python.
    -- With no interpreter anywhere, say nothing: basedpyright then works off
    -- its bundled typeshed, which still type-checks the code in front of you.
    local py = python.interpreter(config.root_dir)
    if not py then return end
    config.settings = config.settings or {}
    config.settings.python = vim.tbl_extend("force", config.settings.python or {}, {
      pythonPath = py,
    })
  end,
})

vim.lsp.config("ruff", {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
  init_options = {
    settings = {
      -- Everything else comes from the project's pyproject.toml / ruff.toml.
      lineLength = 88,
      fixAll = true,
      organizeImports = true,
    },
  },
})

-- Only useful for editing this config; enabled when the server happens to exist.
vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", ".git" },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = { checkThirdParty = false, library = vim.api.nvim_get_runtime_file("", true) },
      diagnostics = { globals = { "vim" } },
      telemetry = { enable = false },
    },
  },
})

for _, server in ipairs({ "basedpyright", "ruff", "lua_ls" }) do
  local cmd = vim.lsp.config[server].cmd[1]
  if vim.fn.executable(cmd) == 1 then
    vim.lsp.enable(server)
  end
end

-- -------------------------------------------------------------- on attach ----
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("devbox_lsp_attach", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end
    local buf = args.buf
    local function map(lhs, rhs, desc, mode)
      vim.keymap.set(mode or "n", lhs, rhs, { buffer = buf, desc = "LSP: " .. desc })
    end

    -- ruff's hover is a stub; let basedpyright answer K.
    if client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end

    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("gD", vim.lsp.buf.declaration, "Go to declaration")
    map("gy", vim.lsp.buf.type_definition, "Go to type definition")
    map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "v" })
    map("<leader>cs", vim.lsp.buf.document_symbol, "Document symbols")

    if client:supports_method("textDocument/inlayHint") then
      map("<leader>ch", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
      end, "Toggle inlay hints")
    end

    -- Highlight the other uses of whatever the cursor is sitting on.
    if client:supports_method("textDocument/documentHighlight") then
      local group = vim.api.nvim_create_augroup("devbox_lsp_highlight_" .. buf, { clear = true })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = group, buffer = buf, callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = group, buffer = buf, callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

-- :LspInfo without a plugin.
vim.api.nvim_create_user_command("LspInfo", function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if vim.tbl_isempty(clients) then
    vim.notify("no language server attached to this buffer", vim.log.levels.WARN)
    return
  end
  local lines = {}
  for _, c in ipairs(clients) do
    table.insert(lines, ("%s  root=%s  pid=%s"):format(c.name, c.root_dir or "-", c:is_stopped() and "stopped" or "running"))
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end, { desc = "Language servers attached to this buffer" })
