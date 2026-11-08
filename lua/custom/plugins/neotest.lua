return {
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'mfussenegger/nvim-dap',
      'nvim-neotest/neotest-python',
    },
    config = function()
      require('neotest').setup {
        adapters = {
          require 'neotest-python' {
            dap = { justMyCode = false },
            runner = 'pytest',
          },
        },
      }

      local neotest = require 'neotest'

      -- vim.keymap.set('n', '<leader>tt', function()
      --   neotest.run.run()
      -- end, { desc = 'Test: Run nearest' })
      --
      -- vim.keymap.set('n', '<leader>tT', function()
      --   neotest.run.run(vim.fn.expand '%')
      -- end, { desc = 'Test: Run file' })

      vim.keymap.set('n', '<leader>dt', function()
        neotest.run.run { strategy = 'dap' }
      end, { desc = 'Test: Debug nearest' })

      -- vim.keymap.set('n', '<leader>ts', function()
      --   neotest.summary.toggle()
      -- end, { desc = 'Test: Toggle summary' })
      --
      -- vim.keymap.set('n', '<leader>to', function()
      --   neotest.output.open { enter = true, auto_close = true }
      -- end, { desc = 'Test: Open output' })
      --
      -- vim.keymap.set('n', '<leader>tx', function()
      --   neotest.run.stop()
      -- end, { desc = 'Test: Stop' })
    end,
  },
}
