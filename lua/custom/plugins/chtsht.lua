return {
  '13janderson/chtsht.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    require('chtsht').setup '<leader>sc'
  end,
}
