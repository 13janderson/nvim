return {
  {
    'tpope/vim-fugitive',
    dependencies = {
      'justinmk/vim-ug',
    },
    config = function(_)
      -- Use navigating merge conflict defaults for now [c for previous ]c for next conflict
      -- Set keybindings for resolving merge conflicts
      vim.keymap.set({ 'n', 'v' }, '<leader>(', ':diffget //2<CR>')
      vim.keymap.set({ 'n', 'v' }, '<leader>)', ':diffget //3<CR>')
      -- vim.keymap.set({ 'n', 'v' }, '<leader>(', 'd2o')
      -- vim.keymap.set({ 'n', 'v' }, '<leader>)', 'd3o')

      vim.keymap.set('n', '<leader>co', function()
        vim.cmd 'G commit -a'
      end)

      -- git log
      vim.keymap.set('n', 'Ul', function()
        vim.cmd 'G log'
      end)

      -- -- git log --oneline
      vim.keymap.set('n', '1Ul', function()
        vim.cmd 'G log --oneline'
      end)

      -- git log --oneline for current file
      vim.keymap.set('n', '1UL', function()
        vim.cmd 'G log --oneline %'
      end)

      -- git log for current file
      vim.keymap.set('n', 'UL', function()
        vim.cmd 'G log %'
      end)
    end,
  },
  {
    'justinmk/vim-ug',
    config = function()
      -- keymap overrides
      vim.keymap.set('n', '<c-p>', '<c-^>', { noremap = false, silent = true })
      local capture = require "custom.my.capture"
      vim.keymap.set('n', '<C-n>', capture.open, { desc = "Capture to today's daily note" })


      local function push()
        local protected = { "main", "master", "develop", "dev" }
        local current = vim.fn.system('git branch --show-current')
        if vim.tbl_contains(protected, current) then
          vim.notify('cannot push to protected branch', vim.log.levels.ERROR)
          return
        end

        vim.cmd('G push')
      end


      vim.keymap.set('n', 'Up', push, { desc = 'Git: push' })
      vim.keymap.set('n', 'UP', 'G Pull<CR>', { desc = 'Git: pull' })

      vim.keymap.set('n', 'Uo', '<cmd>G checkout -<CR>', { desc = 'Git: previous branch' })
      vim.keymap.set('n', 'UO', '<cmd>G checkout -<CR>', { desc = 'Git: previous branch' })

      vim.keymap.set('n', 'Uz', '<cmd>G stash<CR>', { desc = 'Git: stash' })
      vim.keymap.set('n', 'UZ', '<cmd>G stash pop<CR>', { desc = 'Git: stash pop' })
    end,
  },
}
