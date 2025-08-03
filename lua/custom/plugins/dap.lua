return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "williamboman/mason.nvim",
    },
    config = function()
      local dap = require("dap")

      -- Ensure Mason is set up and js-debug-adapter is installed
      require("mason").setup()
      local mason_registry = require("mason-registry")
      if not mason_registry.is_installed("js-debug-adapter") then
        print("Installing js-debug-adapter...")
        vim.cmd("MasonInstall js-debug-adapter")
      end

      -- Check if ts-node is installed
      local ts_node_path = vim.fn.exepath("ts-node")
      if ts_node_path == "" then
        print("Error: ts-node not found. Please install it with 'npm install -g ts-node'")
        return
      end

      -- Configure DAP adapter for JavaScript/TypeScript (vscode-js-debug)
      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "js-debug-adapter",
          args = { "${port}" },
        },
      }

      local ts_filetypes = { "typescript", "typescriptreact" }
      for _, language in ipairs(ts_filetypes) do
        dap.configurations[language] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch TypeScript File",
            program = "${file}",
            runtimeExecutable = "tsx",
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            console = "integratedTerminal",
            internalConsoleOptions = "neverOpen",
            skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },
          },
        }
      end


      dap.set_log_level("TRACE")

      -- Basic DAP keybindings
      vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "DAP: Continue" })
      vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "DAP: Step Over" })
      vim.keymap.set("n", "<leader>dI", dap.step_into, { desc = "DAP: Step Into" })
      vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "DAP: Step Out" })
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP: Toggle Breakpoint" })

      -- Optional: Add breakpoint logging
      -- dap.listeners.after.setBreakpoints["debug_logging"] = function(_, _, response)
      --   if response and response.breakpoints then
      --     for _, bp in ipairs(response.breakpoints) do
      --       print("Breakpoint set: " .. vim.inspect(bp))
      --     end
      --   end
      -- end
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup()

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      -- dap.listeners.after.event_terminated["dapui_config"] = function()
      --   dapui.close()
      -- end
      -- dap.listeners.after.event_exited["dapui_config"] = function()
      --   dapui.close()
      -- end

      vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "DAPUI: Toggle" })
    end,
  },
}
