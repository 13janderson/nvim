return {
  -- Core DAP
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'williamboman/mason.nvim',
      'jay-babu/mason-nvim-dap.nvim',
    },
    config = function()
      local dap = require 'dap'

      -- mason-nvim-dap bridges Mason and nvim-dap so adapters are installed
      -- automatically just like LSPs. This is the closest thing to
      -- "nvim-dap-config" — it handles the boring adapter setup for you.
      require('mason-nvim-dap').setup {
        ensure_installed = {
          'python',       -- debugpy
          'js',           -- js-debug-adapter (pwa-node)
          'node2',        -- node-debug2-adapter (fallback)
        },
        automatic_installation = true,
        handlers = {},
      }

      -- ─── JavaScript / TypeScript ──────────────────────────────────────────
      -- vscode-js-debug (pwa-node) gives the best OOTB experience for Node.
      dap.adapters['pwa-node'] = {
        type = 'server',
        host = 'localhost',
        port = '${port}',
        executable = {
          command = 'js-debug-adapter',
          args = { '${port}' },
        },
      }

      -- Also keep node2 around as a lightweight fallback
      dap.adapters['node2'] = {
        type = 'executable',
        command = 'node-debug2-adapter',
      }

      local js_filetypes = {
        'javascript',
        'javascriptreact',
        'typescript',
        'typescriptreact',
      }

      for _, language in ipairs(js_filetypes) do
        dap.configurations[language] = {
          {
            type = 'pwa-node',
            request = 'launch',
            name = 'Launch file (tsx/ts-node)',
            program = '${file}',
            runtimeExecutable = 'tsx',
            cwd = '${workspaceFolder}',
            sourceMaps = true,
            console = 'integratedTerminal',
            internalConsoleOptions = 'neverOpen',
            skipFiles = { '<node_internals>/**', '${workspaceFolder}/node_modules/**' },
          },
          {
            type = 'pwa-node',
            request = 'launch',
            name = 'Launch file (node)',
            program = '${file}',
            cwd = '${workspaceFolder}',
            sourceMaps = true,
            console = 'integratedTerminal',
            internalConsoleOptions = 'neverOpen',
            skipFiles = { '<node_internals>/**', '${workspaceFolder}/node_modules/**' },
          },
          {
            type = 'pwa-node',
            request = 'attach',
            name = 'Attach to process',
            processId = require('dap.utils').pick_process,
            cwd = '${workspaceFolder}',
            sourceMaps = true,
            skipFiles = { '<node_internals>/**', '${workspaceFolder}/node_modules/**' },
          },
          {
            type = 'pwa-node',
            request = 'launch',
            name = 'Debug Jest Tests',
            runtimeExecutable = 'node',
            runtimeArgs = {
              './node_modules/jest/bin/jest.js',
              '--runInBand',
            },
            rootPath = '${workspaceFolder}',
            cwd = '${workspaceFolder}',
            console = 'integratedTerminal',
            internalConsoleOptions = 'neverOpen',
            skipFiles = { '<node_internals>/**', '${workspaceFolder}/node_modules/**' },
          },
        }
      end

      dap.set_log_level 'TRACE'

      -- ─── Keymaps ──────────────────────────────────────────────────────────
      local function map(lhs, rhs, desc)
        vim.keymap.set('n', lhs, rhs, { desc = 'DAP: ' .. desc })
      end

      map('<leader>dc', dap.continue,          'Continue / Start')
      map('<leader>do', dap.step_over,         'Step Over')
      map('<leader>dI', dap.step_into,         'Step Into')
      map('<leader>dO', dap.step_out,          'Step Out')
      map('<leader>db', dap.toggle_breakpoint, 'Toggle Breakpoint')
      map('<leader>dB', function()
        dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
      end, 'Conditional Breakpoint')
      map('<leader>dr', dap.run_to_cursor,     'Run to Cursor')
      map('<leader>dl', dap.run_last,          'Run Last')
      map('<leader>dp', dap.pause,             'Pause')
      map('<leader>dx', dap.terminate,         'Terminate')

      -- Virtual text for current debug line
      local ok, dap_vt = pcall(require, 'nvim-dap-virtual-text')
      if ok then
        dap_vt.setup()
      end
    end,
  },

  -- Python: OOTB debugging via debugpy + Mason
  {
    'mfussenegger/nvim-dap-python',
    dependencies = {
      'mfussenegger/nvim-dap',
      'williamboman/mason.nvim',
    },
    ft = 'python',
    config = function()
      -- Try to find debugpy via Mason first, fall back to system python
      local mason_registry = require 'mason-registry'
      local debugpy_path
      if mason_registry.is_installed 'debugpy' then
        local pkg = mason_registry.get_package 'debugpy'
        debugpy_path = pkg:get_install_path() .. '/venv/bin/python'
      else
        debugpy_path = vim.fn.exepath 'python3' or vim.fn.exepath 'python'
      end

      require('dap-python').setup(debugpy_path)

      -- Add a "Run pytest at cursor" config
      require('dap').configurations.python = vim.list_extend(
        require('dap').configurations.python or {},
        {
          {
            type = 'python',
            request = 'launch',
            name = 'pytest: current file',
            module = 'pytest',
            args = { '${file}', '-v' },
            console = 'integratedTerminal',
          },
        }
      )
    end,
  },

  -- Go: OOTB debugging via delve
  {
    'leoluz/nvim-dap-go',
    dependencies = {
      'mfussenegger/nvim-dap',
    },
    ft = 'go',
    config = function()
      require('dap-go').setup {
        delve = {
          path = 'dlv',
        },
      }
    end,
  },

  -- UI
  {
    'rcarriga/nvim-dap-ui',
    dependencies = {
      'mfussenegger/nvim-dap',
      'nvim-neotest/nvim-nio',
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      dapui.setup {
        layouts = {
          {
            elements = {
              { id = 'scopes', size = 0.25 },
              { id = 'breakpoints', size = 0.25 },
              { id = 'stacks', size = 0.25 },
              { id = 'watches', size = 0.25 },
            },
            size = 40,
            position = 'left',
          },
          {
            elements = {
              { id = 'repl', size = 0.5 },
              { id = 'console', size = 0.5 },
            },
            size = 10,
            position = 'bottom',
          },
        },
      }

      -- Auto-open when debugging starts; close when session ends
      dap.listeners.after.event_initialized['dapui_config'] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated['dapui_config'] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited['dapui_config'] = function()
        dapui.close()
      end

      vim.keymap.set('n', '<leader>du', dapui.toggle, { desc = 'DAPUI: Toggle' })
      vim.keymap.set('n', '<leader>dR', function()
        dapui.float_element('repl', { enter = true })
      end, { desc = 'DAPUI: Float REPL' })
    end,
  },

  -- Optional: inline variable values while debugging
  {
    'theHamsta/nvim-dap-virtual-text',
    dependencies = { 'mfussenegger/nvim-dap' },
    opts = {
      enabled = true,
      enabled_commands = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = false,
      show_stop_reason = true,
      commented = false,
      only_first_definition = true,
      all_references = false,
      filter_references_pattern = '<module',
      virt_text_pos = 'eol',
      all_frames = false,
      virt_lines = false,
      virt_text_win_col = nil,
    },
  },
}
