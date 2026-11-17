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

      vim.keymap.set('n', ']t', function()
        neotest.jump.next()
      end, { desc = 'Test: Next test' })
      vim.keymap.set('n', '[t', function()
        neotest.jump.prev()
      end, { desc = 'Test: Previous test' })

      vim.keymap.set('n', '<leader>tt', function()
        neotest.run.run()
      end, { desc = 'Test: Run nearest' })

      vim.keymap.set('n', '<leader>tf', function()
        neotest.run.run(vim.fn.expand '%')
      end, { desc = 'Test: Run file' })

      vim.keymap.set('n', '<leader>ts', function()
        neotest.summary.toggle()
      end, { desc = 'Test: Toggle summary' })

      vim.keymap.set('n', '<leader>to', function()
        neotest.output.open { enter = true, auto_close = true }
      end, { desc = 'Test: Open output' })

      vim.keymap.set('n', '<leader>tx', function()
        neotest.run.stop()
      end, { desc = 'Test: Stop' })

      vim.keymap.set('n', '<leader>dt', function()
        neotest.run.run { strategy = 'dap' }
      end, { desc = 'Test: Debug nearest' })

      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'neotest-output', 'neotest-output-panel', 'neotest-summary' },
        callback = function(args)
          local close
          if vim.bo[args.buf].filetype == 'neotest-summary' then
            close = function()
              require('neotest').summary.close()
            end
          elseif vim.bo[args.buf].filetype == 'neotest-output-panel' then
            close = function()
              require('neotest').output_panel.close()
            end
          else
            close = function()
              pcall(vim.api.nvim_win_close, 0, true)
            end
          end

          vim.keymap.set('n', 'q', close, { buffer = args.buf, desc = 'Close Neotest window' })
        end,
      })
    end,
  },
}
