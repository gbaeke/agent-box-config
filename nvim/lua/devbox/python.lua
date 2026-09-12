-- Finding the interpreter a project actually uses.
--
-- basedpyright needs to be told, or it resolves imports against the system
-- python and reports half the third-party imports as missing. The rules, in
-- order: an activated virtualenv, a .venv/ or venv/ beside the project root,
-- then whatever python3 is on PATH.

local M = {}

local function executable(path)
  return path and vim.fn.executable(path) == 1 and path or nil
end

--- The directory a project rooted at `start` lives in.
--- @param start string|nil  a file or directory to search upward from
--- @return string root
function M.root(start)
  local markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".venv", ".git" }
  local found = vim.fs.find(markers, {
    path = start or vim.fn.expand("%:p:h"),
    upward = true,
    stop = vim.uv.os_homedir(),
  })[1]
  return found and vim.fs.dirname(found) or vim.uv.cwd()
end

--- The python interpreter to use for a project.
--- @param root string|nil  project directory; defaults to the current file's
--- @return string|nil path  nil when the box has no python at all, which is
---   a real case: uv-managed interpreters live inside venvs, so a fresh
---   machine can have no system python3 and still run Python projects.
function M.interpreter(root)
  local active = vim.env.VIRTUAL_ENV
  if active then
    local py = executable(active .. "/bin/python")
    if py then return py end
  end

  root = root or M.root()
  for _, dir in ipairs({ ".venv", "venv", "env" }) do
    local py = executable(root .. "/" .. dir .. "/bin/python")
    if py then return py end
  end

  return executable(vim.fn.exepath("python3"))
end

--- Where the virtualenv lives, if there is one. Shown in the statusline.
--- @return string|nil
function M.venv_name()
  local py = M.interpreter()
  if not py then return nil end
  local venv = py:match("^(.*)/bin/python$")
  if not venv or venv == "/usr" or venv == "" then return nil end
  local name = vim.fs.basename(venv)
  -- ".venv" says nothing; show the project it belongs to instead.
  if name == ".venv" or name == "venv" or name == "env" then
    name = vim.fs.basename(vim.fs.dirname(venv)) .. "/" .. name
  end
  return name
end

return M
