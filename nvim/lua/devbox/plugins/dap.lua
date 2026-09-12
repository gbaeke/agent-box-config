-- Debugging Python. The adapter runs out of the devbox debugpy venv
-- (~/.local/share/devbox/debugpy), so a project does not need debugpy of its
-- own; the code being debugged still runs under the project's interpreter.

return {
  {
    "mfussenegger/nvim-dap",
    version = "*",
    dependencies = {
      { "rcarriga/nvim-dap-ui", version = "*", dependencies = { "nvim-neotest/nvim-nio" } },
      "theHamsta/nvim-dap-virtual-text",
      "mfussenegger/nvim-dap-python",
    },
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "Conditional breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue / start" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "REPL" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle debug UI" },
      { "<leader>dk", function() require("dapui").eval() end, mode = { "n", "v" }, desc = "Evaluate under cursor" },
      { "<leader>dm", function() require("dap-python").test_method() end, desc = "Debug test method" },
      { "<leader>df", function() require("dap-python").test_class() end, desc = "Debug test class" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup()
      require("nvim-dap-virtual-text").setup({})

      local adapter = vim.fn.expand("~/.local/share/devbox/debugpy/bin/python")
      if vim.fn.executable(adapter) == 0 then
        adapter = require("devbox.python").interpreter() or "python3"
      end
      require("dap-python").setup(adapter, { console = "integratedTerminal" })

      -- The debuggee runs under the project's venv, whatever the adapter is.
      for _, config in ipairs(dap.configurations.python or {}) do
        config.pythonPath = function() return require("devbox.python").interpreter() or adapter end
      end

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticWarn", linehl = "Visual" })

      dap.listeners.after.event_initialized["devbox"] = dapui.open
      dap.listeners.before.event_terminated["devbox"] = dapui.close
      dap.listeners.before.event_exited["devbox"] = dapui.close
    end,
  },
}
