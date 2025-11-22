return {
  '13janderson/chtsht.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  -- Optional setup call to change default keymap behaviour
  -- default is <leader>sc when nothing is passed
  config = function()
    require('chtsht').setup '<leader>sc'
  end,
}
