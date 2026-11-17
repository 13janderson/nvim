return {
  {
    '13janderson/harpoon2',
    branch = 'harpoon2',
    event = 'VimEnter',
    cond = not (vim.startswith(vim.fn.getcwd(), '/tmp') or vim.startswith(vim.fn.expand '%:p', '/tmp')),
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local harpoon = require 'harpoon'
      harpoon:setup {
        settings = {
          save_on_toggle = true,
          save_on_ui_close = true,
          tmux_autoclose_windows = false,
          float_hidden = true,
        },
      }
      vim.keymap.set('n', '<leader>a', function()
        harpoon:list():add()
      end)
      vim.keymap.set('n', '<C-e>', function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end)
    end,
  },
}
